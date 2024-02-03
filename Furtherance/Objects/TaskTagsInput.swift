//
//  TaskTagsInput.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import Foundation

class TaskTagsInput: ObservableObject {
    static let shared = TaskTagsInput()
    @Published var text = ""
    @Published var debouncedText = ""
    
    init() {
        setupTextDebounce()
    }
    
    func setupTextDebounce() {
        debouncedText = self.text
        $text
            .debounce(for: 1, scheduler: RunLoop.main)
            .assign(to: &$debouncedText)
    }
}
