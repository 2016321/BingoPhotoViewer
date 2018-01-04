//
//  BExtension_Array.swift
//  BingoPhotoViewerDemo
//
//  Created by 王昱斌 on 2018/1/2.
//  Copyright © 2018年 Qtin. All rights reserved.
//

import Foundation

extension Array{
    
    func insert(_ element: Element, isOrderedBefore: (Element, Element) -> Bool) -> (index: Int, alreadyExists: Bool) {
        var lowIndex : Int = 0
        var highIndex : Int = self.count - 1
        
        while lowIndex <= highIndex {
            let midIndex = (lowIndex + highIndex) / 2
            if isOrderedBefore(self[midIndex], element){
                lowIndex = midIndex + 1
            }else if isOrderedBefore(element, self[midIndex]){
                highIndex = midIndex - 1
            }else{
                return (midIndex, true)
            }
        }
        
        return (lowIndex, false)
        
    }
    
}
