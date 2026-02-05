import SwiftUI

struct ExpenseTemplatesView: View {
    @State private var templates: [ExpenseTemplate] = []
    @State private var showingAddTemplate = false
    @State private var editingTemplate: ExpenseTemplate?
    
    var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()
            AnimatedGradientMeshView().opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Expense Templates")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        showingAddTemplate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentYellow)
                    }
                }
                .padding()
                
                if templates.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentYellow.opacity(0.5))
                        
                        Text("No Templates Yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        Text("Create templates for your frequent expenses")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showingAddTemplate = true
                        } label: {
                            Text("Create Template")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentYellow)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(templates) { template in
                                TemplateRowView(template: template)
                                    .onTapGesture {
                                        editingTemplate = template
                                    }
                                    .contextMenu {
                                        Button {
                                            editingTemplate = template
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            deleteTemplate(template)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            loadTemplates()
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddEditTemplateView(template: nil) {
                loadTemplates()
            }
        }
        .sheet(item: $editingTemplate) { template in
            AddEditTemplateView(template: template) {
                loadTemplates()
            }
        }
    }
    
    private func loadTemplates() {
        templates = DataManager.shared.loadExpenseTemplates()
    }
    
    private func deleteTemplate(_ template: ExpenseTemplate) {
        try? DataManager.shared.deleteExpenseTemplate(template)
        loadTemplates()
    }
}

struct TemplateRowView: View {
    let template: ExpenseTemplate
    
    var body: some View {
        HStack(spacing: 16) {
            CategoryIconView(category: template.category, size: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    Text(template.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    if let note = template.note, !note.isEmpty {
                        Text("• \(note)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Text(template.formattedAmount)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentYellow)
        }
        .padding()
        .glassCard()
    }
}

struct AddEditTemplateView: View {
    let template: ExpenseTemplate?
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var note: String = ""
    
    private var isEditing: Bool { template != nil }
    
    private var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }
    
    var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()
            OrbitalCirclesView()
            
            VStack(spacing: 24) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Text(isEditing ? "Edit Template" : "New Template")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: saveTemplate) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isValid ? Color.accentYellow : .white.opacity(0.3))
                    }
                    .disabled(!isValid)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("Template Name")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.leading)
                            
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.accentYellow)
                                
                                CustomTextField(
                                    text: $name,
                                    placeholder: "e.g. Morning Coffee",
                                    placeholderColor: UIColor(Color.accentYellow.opacity(0.6)),
                                    textColor: .white,
                                    fontSize: 17,
                                    fontWeight: .regular,
                                    keyboardType: .default,
                                    textAlignment: .left
                                )
                            }
                            .padding()
                            .glassCard()
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Amount")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.leading)
                            
                            AmountTextField(text: $amount)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Category")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.leading)
                            
                            CategoryPickerView(selection: $selectedCategory)
                                .padding()
                                .glassCard()
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Note (optional)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.leading)
                            
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(Color.accentYellow)
                                
                                CustomTextField(
                                    text: $note,
                                    placeholder: "Default note for this expense",
                                    placeholderColor: UIColor(Color.accentYellow.opacity(0.6)),
                                    textColor: .white,
                                    fontSize: 17,
                                    fontWeight: .regular,
                                    keyboardType: .default,
                                    textAlignment: .left
                                )
                            }
                            .padding()
                            .glassCard()
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if let template = template {
                name = template.name
                amount = String(format: "%.2f", template.amount)
                selectedCategory = template.category
                note = template.note ?? ""
            }
        }
    }
    
    private func saveTemplate() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        let newTemplate = ExpenseTemplate(
            id: template?.id ?? UUID(),
            name: name,
            amount: amountValue,
            category: selectedCategory,
            note: note.isEmpty ? nil : note
        )
        
        if isEditing {
            try? DataManager.shared.updateExpenseTemplate(newTemplate)
        } else {
            try? DataManager.shared.saveExpenseTemplate(newTemplate)
        }
        
        onSave()
        dismiss()
    }
}
