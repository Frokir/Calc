//
//  func.swift
//  myCalc
//
//  Created by Олег Переплётчиков on 02.08.2025.
//
import SwiftUI

func clearText(in text: Binding<String>)    {
    text.wrappedValue = "0"
}

func myDropLast(in text: Binding<String>) {
    if !text.wrappedValue.isEmpty {
        text.wrappedValue.removeLast()
    }else{
        text.wrappedValue = "0"
    }
}


func addValue (addText: String, to text: Binding<String>) {
    
    
    switch addText {
    case ".":
        if text.wrappedValue.last == "." {}
        else if !text.wrappedValue.last!.isNumber {
            text.wrappedValue.append("0.")
        } else if text.wrappedValue != "0" && text.wrappedValue.last!.isNumber{
            var make: Bool = true
            var ckeckText = text.wrappedValue
            while make {
                if ckeckText != "" && ckeckText.last!.isNumber {
                    ckeckText.removeLast()
                } else if ckeckText.last == "."{
                    make = false
                } else {
                    make = false
                    text.wrappedValue.append(".")
                }
            }
              
        } else {
            text.wrappedValue.append(addText)
        }
        
    case "-":
        if text.wrappedValue.last != "-" && text.wrappedValue != "0" {
            text.wrappedValue.append(addText)
        } else if text.wrappedValue == "0" {
            text.wrappedValue = "-"
        }
    case "0":
        if text.wrappedValue != "0" && text.wrappedValue != "-0" {
            text.wrappedValue.append(addText)
        }
    default :
        if text.wrappedValue == "0" {
            text.wrappedValue = addText
        }else {
            text.wrappedValue.append(addText)
        }
    }}


func checkError (text: Binding<String>) -> Bool {
    if text.wrappedValue.count > 10 {
        return true
    }
    return false
}

func resultValue (text: Binding<String>) {
    
    
    
    
    
    text.wrappedValue = "0"
}

