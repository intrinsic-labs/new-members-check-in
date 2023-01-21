//
//  CCCTitleView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

enum CCCTitleViewStyle {
    case vertical
    case horizontal
}

struct CCCTitleView: View {
    var message: String? = nil
    var messageSize: CGFloat = 20
    var showMessage: Bool = true
    var omitTagline: Bool = false
    var viewStyle: CCCTitleViewStyle
    
    var body: some View {
        
        if viewStyle == .horizontal {
            VStack {
                HStack(spacing: 15) {
                    Image("CCClogo.white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 65)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CHRIST COVENANT CHURCH")
                            .cccTitle()
                        if omitTagline == false {
                            Text("Standing on truth. Walking in grace.")
                                .cccSubtitle()
                        }
                    }
                }.padding(30)
                if showMessage {
                    Text(message ?? "No message provided").cccBody(fontSize: messageSize)
                        .multilineTextAlignment(.center)
                }
            }.padding(30)
        }
        
        if viewStyle == .vertical {
            VStack(spacing: 20) {
                Image("CCClogo.white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                VStack(alignment: .center, spacing: 3) {
                    if omitTagline {
                        Text("CHRIST COVENANT")
                            .cccTitle()
                        HStack(spacing: 10) {
                            Color.white
                                .frame(width: 90, height: 1)
                            Text("CHURCH")
                                .cccSubtitle(italic: false)
                            Color.white
                                .frame(width: 90, height: 1)
                        }
                    } else {
                        Text("CHRIST COVENANT")
                            .cccTitle()
                        HStack(spacing: 10) {
                            Color.white
                                .frame(width: 90, height: 1)
                            Text("CHURCH")
                                .cccSubtitle(italic: false)
                            Color.white
                                .frame(width: 90, height: 1)
                        }
                        Text("Standing on truth. Walking in grace.")
                            .cccBody(fontSize: 20, italic: true)
                            .padding(30)
                    }
                }
                if showMessage {
                    Text(message ?? "No message provided").cccBody(fontSize: messageSize)
                        .padding(30)
                        .multilineTextAlignment(.center)
                }
            }
        }
        
    }
}

struct CCCTitle: ViewModifier {
    var italic: Bool
    func body(content: Content) -> some View {
        content
            .font(.custom(italic ? "Palatino Italic" : "Palatino", size: 32))
            .foregroundColor(.white)
            .tracking(1.1)
            .multilineTextAlignment(.center)
    }
}

struct CCCSubtitle: ViewModifier {
    var italic: Bool
    func body(content: Content) -> some View {
        content
            .font(.custom(italic ? "Palatino Italic" : "Palatino", size: 24))
            .foregroundColor(.white)
            .tracking(1)
    }
}

struct CCCBody: ViewModifier {
    var fontSize: CGFloat
    var italic: Bool
    func body(content: Content) -> some View {
        content
            .font(.custom(italic ? "Palatino Italic" : "Palatino", size: fontSize))
            .foregroundColor(.white)
            .tracking(1)
    }
}

extension View {
    func cccTitle(italic: Bool = false) -> some View {
        modifier(CCCTitle(italic: italic))
    }
    func cccSubtitle(italic: Bool = true) -> some View {
        modifier(CCCSubtitle(italic: italic))
    }
    func cccBody(fontSize: CGFloat = 20, italic: Bool = false) -> some View {
        modifier(CCCBody(fontSize: fontSize, italic: italic))
    }
}

