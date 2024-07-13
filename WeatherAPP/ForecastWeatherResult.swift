//
//  ForecastWeatherResult.swift
//  WeatherAPP
//
//  Created by 김승희 on 7/12/24.
//

import Foundation

struct ForecastWeatherResult: Codable {
    let list: [ForecastWeather]
}

struct ForecastWeather: Codable {
    let main: WeatherMain
    let dtTxt: String
    
    enum CodingKeys: String, CodingKey {
        case main
        case dtTxt = "dt_txt"
    }
}
