import Foundation

struct Forecast: Codable, Identifiable {
    let id = UUID() // so SwiftUI can ForEach
    let ymdt: String        // date/time like 2025082300
    let sky: String         // e.g. "맑음"
    let skycode: String     // e.g. "1"
    let rain: String
    let rainAmt: String
    let temp: String
    let winddir: String
    let windspd: String
    let humidity: String
    let wavePrd: String
    let waveHt: String
    let waveDir: String

    enum CodingKeys: String, CodingKey {
        case ymdt, sky, skycode, rain, waveDir
        case rainAmt = "﻿rainAmt"
        case temp = "﻿temp"
        case winddir = "﻿winddir"
        case windspd = "﻿﻿windspd"
        case humidity = "﻿﻿humidity"
        case wavePrd = "﻿﻿﻿wavePrd"
        case waveHt = "﻿﻿﻿﻿waveHt"
    }
}

