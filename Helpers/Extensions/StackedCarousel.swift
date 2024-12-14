//
//  StackedCarousel.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/13/24.
//

import UIKit
import SwiftUI

// MARK: Custom View
struct SwipeCarousel<Content: View, ID, Item>: View where Item: RandomAccessCollection, Item.Element: Equatable, Item.Element: Identifiable, ID: Hashable {
    
    var id: KeyPath<Item.Element, ID>
    var items: Item
    
    //MARK: Creating a Custom View like ForEach
    var content: (Item.Element, CGSize) -> Content
    var trailingCards: Int = 3
    
    init(items: Item, id: KeyPath<Item.Element, ID>, trailingCards: Int = 3, @ViewBuilder content: @escaping (Item.Element, CGSize) -> Content) {
        self.id = id
        self.items = items
        self.content = content
        self.trailingCards = trailingCards
    }
    
    @State var offset: CGFloat = 0
    @State var showRight: Bool = false
    @State var currentIndex: Int = 0
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ZStack {
                ForEach(items) { item in
                    CardView(item: item, size: size)
                        .overlay(
                            content: {
                                let index = indexOf(item: item)
                                if (currentIndex + 1) == index && Array(
                                    items
                                ).indices
                                    .contains(currentIndex - 1) && showRight {
                                    CardView(item: Array(items)[currentIndex - 1], size: size)
                                        .transition(.identity)
                                }
                                    
                            })
                        .zIndex(zIndex(for: item))
                    
                    
                }
            }
            .animation(.easeInOut(duration: 0.25), value: offset == .zero)
            .frame(width: .infinity, height: .infinity)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        showRight = value.translation.width > 0
                        offset = (value.translation.width / size.width) * (size.width / 1.2)
                    })
                    .onEnded({ value in
                        let translation = value.translation.width
                        
                        if translation > 0 {
                            //MARK: Swipe Right
                            decreaseIndex(translation: translation)
                        } else {
                            //MARK: Swipe Left
                            increaseIndex(translation: translation)
                        }
                        
                        withAnimation(.easeInOut(duration: 0.25)) {
                            offset = .zero
                        }
                    })
            )
        }
    }
    
    @ViewBuilder
    func CardView(item: Item.Element, size: CGSize) -> some View {
        let index = indexOf(item: item)
        content(item, size)
        //MARK: Shadow
            .shadow(color: .black.opacity(0.25), radius: 5, x: 5, y: 5)
            .scaleEffect(scaleFor(item: item))
            .rotationEffect(
                .degrees(Double(rotationFor(item: item))),
                anchor: currentIndex > index ? .topLeading : .topTrailing
            )
            .offset(x: offsetFor(item: item))
        //MARK: Offset
            .offset(x: currentIndex == index ? offset : 0)
            .rotationEffect(
                .init(degrees: rotationForGesture(index: index)),
                anchor: .top
            )
            .scaleEffect(scaleForGesture(index: index))
    }
    
    
    func increaseIndex(translation: CGFloat) {
        if translation < 0 && -translation > 110 && currentIndex < (items.count - 1) {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentIndex += 1
            }
        }
    }
    
    func decreaseIndex(translation: CGFloat) {
        if translation > 0 && translation > 110 && currentIndex > 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentIndex -= 1
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showRight = false
            }
               
        }
    }
    
    func rotationForGesture(index: Int) -> CGFloat {
        let progress = (offset / screenSize.width) * 30
        return (currentIndex == index ? (progress > 0.75 ? progress : 0.75) : 1)
    }
    
    func scaleForGesture(index: Int) -> CGFloat {
        let progress = 1 - ((offset > 0 ? offset : -offset) / screenSize.width)
        return (currentIndex == index ? progress : 1)
    }
    
    func rotationFor(item: Item.Element) -> CGFloat {
        let index = indexOf(item: item) - currentIndex
        if index > 0 {
            if index > trailingCards {
                return (CGFloat(trailingCards) * 3)
            }
            return CGFloat(index) * 3
        }
        
        if -index > trailingCards {
            return (-CGFloat(trailingCards) * 3)
        }
        return CGFloat(index) * 3
    }
    
    func scaleFor(item: Item.Element) -> CGFloat {
        let index = indexOf(item: item) - currentIndex
        if index > 0 {
            if index > trailingCards {
                return 1 - (CGFloat(trailingCards) / 20)
            }
            
            return 1 - (CGFloat(index) / 20)
        }
        
        if -index > trailingCards {
            return 1 - (CGFloat(trailingCards) / 20)
        }
        
        return 1 + (CGFloat(index) / 20)
    }
    
    func offsetFor(item: Item.Element) -> CGFloat {
        let index = indexOf(item: item) - currentIndex
        if index > 0 {
            if index > trailingCards {
                return 20 * CGFloat(trailingCards)
            }
            return CGFloat(index) * 20
        }
        
        if -index > trailingCards {
            return -20 * CGFloat(trailingCards)
        }
        return CGFloat(index) * 20
    }
    
    
    //MARK: ZIndex Value for each card
    func zIndex(for item: Item.Element) -> Double {
        let index = indexOf(item: item)
        let totalCount = items.count
        
        return currentIndex == index ? 10 : (
            currentIndex < index ? Double(totalCount - index) : Double(index - totalCount)
        )
    }
    
    func indexOf(item: Item.Element) -> Int {
        let arrayItems = Array(items)
        if let index = arrayItems.firstIndex(of: item) {
            return index
        }
        return 0
    }
    
    var screenSize: CGSize {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .zero
        }
        return window.screen.bounds.size
    }
}

