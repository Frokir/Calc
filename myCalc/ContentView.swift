//
//  ContentView.swift
//  myCalc
//
//  Created by Олег Переплётчиков on 31.07.2025.
//

import SwiftUI

enum TipicalButtonStyle {
    case TitleOnly
    case TitleAndIcon
}

//Структура описывающая типовую кнопку

struct TipicalButton: View {
    var text: String
    var action: () -> Void = {}
    var color : Color = .blue
    var myLabelStyle: TipicalButtonStyle = .TitleOnly
    var iconName: String? = nil
    
       
    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundColor(.white)
                .font(.title2)
                .frame(width: 70, height: 70)
                .background(color)
                .clipShape(.circle)
                //.labelStyle(.titleOnly)
        }
        .frame(width: 50, height: 50)
        .contentShape(Circle())
        .padding(10)
        
    }
}


//Основное тело программы

struct ContentView: View {
    @State var mainText: String = "0"
    

    var body: some View {
        VStack {
            Spacer()
            HStack{
                Spacer()
                
                Text(mainText)
                    .padding()
            }
            
            VStack {
                HStack
                {
                    TipicalButton(text: "AC", action: {clearText(in: $mainText)})
                    TipicalButton(text: "(", action: {addValue(addText: "(", to: $mainText)})
                    TipicalButton(text: ")", action: {addValue(addText: ")", to: $mainText)})
                    TipicalButton(text: "backspace", action: {myDropLast(in: $mainText)})
                    
                }
                HStack
                {
                    TipicalButton(text: "7", action: {addValue(addText: "7", to: $mainText)})
                    TipicalButton(text: "8", action: {addValue(addText: "8", to: $mainText)})
                    TipicalButton(text: "9", action: {addValue(addText: "9", to: $mainText)})
                    TipicalButton(text: "/", action: {addValue(addText: "/", to: $mainText)})
                    
                    
                }
                HStack
                {
                    TipicalButton(text: "4", action: {addValue(addText: "4", to: $mainText)})
                    TipicalButton(text: "5", action: {addValue(addText: "5", to: $mainText)})
                    TipicalButton(text: "6", action: {addValue(addText: "6", to: $mainText)})
                    TipicalButton(text: "*", action: {addValue(addText: "*", to: $mainText)})
                }
                HStack
                {
                    TipicalButton(text: "1", action: {addValue(addText: "1", to: $mainText)})
                    TipicalButton(text: "2", action: {addValue(addText: "2", to: $mainText)})
                    TipicalButton(text: "3", action: {addValue(addText: "3", to: $mainText)})
                    TipicalButton(text: "-", action: {addValue(addText: "-", to: $mainText)})
                }
                HStack
                {
                    
                    TipicalButton(text: "0", action: {addValue(addText: "0", to: $mainText)})
                    TipicalButton(text: ".", action: {addValue(addText: ".", to: $mainText)})
                    TipicalButton(text: "=", action: {addValue(addText: "=", to: $mainText)})
                    TipicalButton(text: "+", action: {addValue(addText: "+", to: $mainText)})
                }
            }
            .frame(maxWidth: .infinity)
            
            
        }
        .padding()
    }
    
}

#Preview {
    ContentView()
}
    