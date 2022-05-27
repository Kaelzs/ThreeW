//
//  Executing.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import Foundation

enum InputError: Error, CustomStringConvertible {
    case invalidDate
    case invalidApp

    var description: String {
        switch self {
        case .invalidDate:
            return "Input date is not valid"
        case .invalidApp:
            return "please select an app"
        }
    }
}

extension ThreeWEvent.When {
    func dateToExecute() throws -> Date {
        switch self {
        case .next(let hour, let minute, let second):
            let date = Date()
            guard let todaysDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: second, of: date) else {
                throw InputError.invalidDate
            }
            if todaysDate <= date {
                guard let targetDate = Calendar.current.date(byAdding: .day, value: 1, to: todaysDate) else {
                    throw InputError.invalidDate
                }
                return targetDate
            } else {
                return todaysDate
            }
        case .timeAfter(let hour, let minute, let second):
            let date = Date()
            let components = DateComponents(hour: hour, minute: minute, second: second)
            guard let targetDate = Calendar.current.date(byAdding: components, to: date) else {
                throw InputError.invalidDate
            }
            return targetDate
        case .specific(let date):
            return date
        }
    }

    func toAppleScriptVariable(withName name: String) throws -> String {
        let date = try dateToExecute()
        let ymdhms = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return "tell the (current date) to set [\(name), year, its month, day, time] to [it, \(ymdhms.year!), \(ymdhms.month!), \(ymdhms.day!), \(ymdhms.hour!) * hours + \(ymdhms.minute!) * minutes + \(ymdhms.second!)]"
    }
}

extension ThreeWEvent.Which {
    func toApp() throws -> String {
        switch self {
        case .app(_, let appID):
            return "application id \"\(appID)\""
        case .none:
            throw InputError.invalidApp
        }
    }
}

extension ThreeWEvent.What {
    func toExecutableString() -> String {
        actions.map { $0.actionString }.joined(separator: "\ndelay 0.1\n")
    }
}

extension ThreeWEvent {
    func toAppleScript() throws -> String {
//        let appleScriptVariable = try when.toAppleScriptVariable(withName: "targetDate")
//        let app = try which.toApp()
//        return """
//        tell application "System Events"
//            \(appleScriptVariable)
//            repeat
//                if targetDate <= (current date) then
//                    tell \(app) to activate
//                        \(what.toExecutableString())
//                    exit repeat
//                end if
//            end repeat
//        end tell
//        """
        let app = try which.toApp()
        return """
        tell application "System Events"
            tell \(app) to activate
                \(what.toExecutableString())
        end tell
        """
    }
}
