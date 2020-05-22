enum Hello {
    func hello() { print("hello") }
}

print(MemoryLayout<Hello>.size)

