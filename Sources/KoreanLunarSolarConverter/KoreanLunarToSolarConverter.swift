//
//  KoreanLunarToSolarConverter.swift
//  KoreanLunarConverter
//
//  Created by SwiftMan on 2022/12/07.
//

import Foundation

public final class KoreanLunarToSolarConverter {
  private let dataSource = KoreanLunarDataSource()
  private let lunarAlgorithm = KoreanLunarAlgorithm()
  private let solarAlgorithm = KoreanSolarAlgorithm()
  private let lunarDateRangeChecker = LunarDateRangeChecker()
  
  public init() {
    
  }

  public func solarDate(fromLunar lunarDate: Date) throws -> KoreanDate {
    guard lunarDateRangeChecker.isValidDate(lunarDate: lunarDate)
    else { throw KoreanLunarConvertError.invalidDate }

    let isIntercalation = dataSource.lunarIntercalationMonth(year: lunarDate.year) == lunarDate.month
    
    let date: Date
    do {
      date = try solarDate(fromLunarDate: lunarDate, isIntercalation: isIntercalation)
    } catch {
      throw error
    }
    
    return KoreanDate(date: date, isIntercalation: isIntercalation)
  }
}

extension KoreanLunarToSolarConverter {
  private func solarDate(fromLunarDate date: Date, isIntercalation: Bool) throws -> Date {
    let lunarYear = date.year
    let absDays = lunarAlgorithm.lunarAbsDays(year: lunarYear,
                                              month: date.month,
                                              day: date.day,
                                              isIntercalation: isIntercalation)
    
    let solarYear = calculateSolarYear(fromLunarYear: lunarYear, absDays: absDays)
    var solarMonth = 0
    var solarDay = 0

    for month in stride(from: 12, through: 1, by: -1) {
      let absDaysByMonth = solarAlgorithm.solarAbsDays(year: solarYear,
                                                       month: month,
                                                       day: 1)
      if absDays >= absDaysByMonth {
        solarMonth = month
        solarDay = absDays - absDaysByMonth + 1
        break
      }
    }
    
    guard
      !isRemovedGregorianCalendarDate(solarYear: solarYear,
                                      solarMonth: solarMonth,
                                      solarDay: solarDay)
    else { throw KoreanLunarConvertError.invalidDate }

    var solarDate = Date()
    solarDate.year = solarYear
    solarDate.month = solarMonth
    solarDate.day = solarDay

    return solarDate
  }
  
  private func calculateSolarYear(fromLunarYear lunarYear: Int, absDays: Int) -> Int {
    if absDays < solarAlgorithm.solarAbsDays(year: lunarYear + 1,
                                             month: 1,
                                             day: 1) {
      return lunarYear
    }
    
    return lunarYear + 1
  }
  
  private func isRemovedGregorianCalendarDate(solarYear: Int,
                                              solarMonth: Int,
                                              solarDay: Int) -> Bool {
    if solarYear == 1582 && solarMonth == 10 {
      return solarDay > 4 && solarDay < 15
    }
    return false
  }
}
