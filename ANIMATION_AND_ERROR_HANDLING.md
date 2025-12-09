# MomentumOS - Animation & Error Handling Guide

## 🎬 Animation Patterns Used

### 1. Transition Animations

#### Opacity + Scale (Content Appearance)
```swift
ForEach(items) { item in
    ItemView(item: item)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
}

// Usage: Cards appearing/disappearing, list items
```

#### Opacity + Move (Expandable Content)
```swift
if isExpanded {
    ExpandedContent()
        .transition(.opacity.combined(with: .move(edge: .top)))
}

// Usage: Hidden details sliding in
```

#### Rotation (Interactive Elements)
```swift
Image(systemName: "chevron.right")
    .rotationEffect(.degrees(isExpanded ? 90 : 0))
    .animation(.easeInOut(duration: 0.3), value: isExpanded)

// Usage: Chevrons, expand indicators
```

---

### 2. Interactive Animations

#### Scale on Press (Button Feedback)
```swift
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Apply to buttons: .buttonStyle(ScaleButtonStyle())
```

#### Scale on Selection (Visual Feedback)
```swift
Button(action: { selectedMood = mood }) {
    VStack { ... }
}
.scaleEffect(selectedMood == mood ? 1.08 : 1.0)
.animation(.easeInOut(duration: 0.2), value: selectedMood)

// Usage: Mood selector, category selector
```

---

### 3. Progress Animations

#### Circular Progress Ring
```swift
ZStack {
    Circle()
        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
    
    Circle()
        .trim(from: 0, to: progressValue)
        .stroke(
            LinearGradient(...),
            style: StrokeStyle(lineWidth: 12, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.linear, value: progressValue)
}
.frame(width: 240, height: 240)

// Usage: Focus timer, calorie tracking
```

#### Linear Progress Bar
```swift
GeometryReader { geometry in
    ZStack(alignment: .leading) {
        Capsule()
            .fill(Color.gray.opacity(0.2))
        
        Capsule()
            .fill(gradient)
            .frame(width: geometry.size.width * percentage)
            .animation(.easeInOut(duration: 0.3), value: percentage)
    }
}
.frame(height: 8)

// Usage: Macro bars, habit progress
```

#### Gradient Progress Ring
```swift
Circle()
    .trim(from: 0, to: min(percentage, 1.0))
    .stroke(
        LinearGradient(
            gradient: Gradient(colors: [MomentumColors.primary, MomentumColors.accent]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        style: StrokeStyle(lineWidth: 8, lineCap: .round)
    )
    .rotationEffect(.degrees(-90))
    .animation(.easeInOut(duration: 0.5), value: percentage)

// Usage: Calorie circular indicator
```

---

### 4. View-Level Animations

#### Smooth State Changes
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    focusManager.pauseSession()
}

// Usage: State changes triggered by user actions
```

#### Grouped Animations
```swift
withAnimation(.easeInOut(duration: 0.2)) {
    selectedCategory = category
}

// Duration: 0.2s for quick feedback
// Duration: 0.3s for standard transitions
// Duration: 0.5s for complex animations
```

---

## 🛡️ Error Handling Patterns

### 1. Validation Error Enums

```swift
enum InputValidationError: LocalizedError {
    case emptyInput
    case invalidValue
    case outOfRange
    
    var errorDescription: String? {
        switch self {
        case .emptyInput: return "This field cannot be empty"
        case .invalidValue: return "Please enter a valid value"
        case .outOfRange: return "Value must be between X and Y"
        }
    }
}
```

### 2. Form Validation Pattern

```swift
@State private var errorMessage: String?
@State private var showError = false

func saveData() {
    do {
        // Validate input
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw InputValidationError.emptyInput
        }
        
        guard valueRange.contains(numericValue) else {
            throw InputValidationError.outOfRange
        }
        
        // Perform action
        try performSave()
        
        // Show success (optional)
        showSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSuccessMessage = false
        }
        
    } catch {
        errorMessage = error.localizedDescription
        showError = true
    }
}
```

### 3. Error Alert Implementation

```swift
.alert("Error Title", isPresented: $showError) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage ?? "An error occurred")
}
```

### 4. Async Error Handling

```swift
@State private var isLoading = false
@State private var errorMessage: String?
@State private var showError = false

func performAsyncAction() {
    isLoading = true
    
    Task {
        do {
            try await asyncOperation()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}
```

### 5. Loading State Pattern

```swift
Button(action: startAction) {
    HStack(spacing: 8) {
        if isLoading {
            ProgressView()
                .tint(MomentumColors.primary)
        } else {
            Image(systemName: "play.fill")
        }
        
        Text(isLoading ? "Starting..." : "Start")
            .fontWeight(.semibold)
    }
}
.disabled(isLoading)
.opacity(isLoading ? 0.7 : 1.0)
```

---

## 🎨 Animation Timing Guide

### Standard Durations
- **Quick Feedback**: 0.1s (button press)
- **Normal Transition**: 0.2-0.3s (selection, expansion)
- **Progress Update**: 0.3-0.5s (bars, timers)
- **Page Transition**: 0.3-0.4s (sheet, navigation)
- **Complex Animation**: 0.5-0.8s (multi-step)

### Animation Functions
- **Linear**: Progress bars, timers (continuous motion)
- **EaseInOut**: Most user interactions (smooth start/end)
- **EaseIn**: Elements entering
- **EaseOut**: Elements exiting

---

## 📋 Error Handling Checklist

For each form/user action, ensure:
- [ ] Input validation with specific error enum
- [ ] Clear error messages in LocalizedError
- [ ] @State variables for error tracking
- [ ] .alert() modifier for error display
- [ ] Try-catch block around risky operations
- [ ] Disabled state while loading/validating
- [ ] Success feedback after completion
- [ ] Field reset on successful submission

---

## 🎯 Best Practices Applied

### Animations
1. **Purposeful**: Every animation has a functional reason
2. **Consistent**: Same actions use same animations
3. **Responsive**: Animations start immediately (no delay)
4. **Smooth**: Proper easing curves for natural motion
5. **Accessible**: Respect system animation settings (prepared for)

### Error Handling
1. **Specific Errors**: Use distinct error cases, not generic
2. **User-Friendly**: Messages explain problem and solution
3. **Non-Blocking**: Errors don't crash or hang app
4. **Recoverable**: Users can fix and retry
5. **Visible**: Clear presentation, not silent failures

---

## 🔧 Common Implementation Examples

### Example 1: Form with Validation
```swift
struct AddItemView: View {
    @State private var itemName = ""
    @State private var value = 100
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isLoading = false
    
    var body: some View {
        Form {
            TextField("Name", text: $itemName)
            Stepper("Value", value: $value)
            
            Button(action: saveItem) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Save")
                }
            }
            .disabled(isLoading)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    private func saveItem() {
        do {
            isLoading = true
            
            guard !itemName.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw ValidationError.emptyName
            }
            
            guard value > 0 else {
                throw ValidationError.invalidValue
            }
            
            // Save logic here
            try performSave()
            
            itemName = ""
            value = 100
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyName
    case invalidValue
    
    var errorDescription: String? {
        switch self {
        case .emptyName: return "Please enter a name"
        case .invalidValue: return "Value must be greater than 0"
        }
    }
}
```

### Example 2: Expandable Card with Animation
```swift
struct ExpandableCard: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Title")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Content
            if isExpanded {
                Divider()
                
                VStack {
                    Text("Hidden content")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .momentumCard()
    }
}
```

---

## 🚀 Performance Considerations

1. **Avoid Excessive Animations**: Don't animate every state change
2. **Use Conditional Rendering**: Only animate visible elements
3. **Optimize Progress Rings**: Use trim() instead of scaling
4. **Async Operations**: Keep animations on main thread
5. **Loading States**: Show spinner for operations >500ms

---

**Last Updated**: December 9, 2025  
**Framework**: SwiftUI 4.0+  
**iOS Minimum**: 16.0+
