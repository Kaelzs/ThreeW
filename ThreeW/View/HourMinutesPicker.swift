//
//  HourMinutesPicker.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import SwiftUI

struct HMSPicker: View {
    @Binding var hms: (Int, Int, Int)

    var body: some View {
        HStack(spacing: 3) {
            TextField("H", value: $hms.0, format: .number)
                .frame(width: 25)
            Text(":")
            TextField("M", value: $hms.1, format: .number)
                .frame(width: 25)
            Text(":")
            TextField("S", value: $hms.2, format: .number)
                .frame(width: 25)
        }
    }
}
