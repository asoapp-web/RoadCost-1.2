import Foundation

struct AppData: Codable {
    var expenses: [Expense] = []
    var incomes: [Income] = []
    var budget: Budget?
    var recurringPayments: [RecurringPayment] = []
    var savingsGoals: [SavingsGoal] = []
    var savingsTransactions: [SavingsTransaction] = []
    var customExpenseCategories: [CustomCategory] = []
    var customIncomeCategories: [CustomCategory] = []
    var expenseTemplates: [ExpenseTemplate] = []
    
    static let key = "RoadCostAppData"
}

struct ExpenseTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var note: String?
    
    init(id: UUID = UUID(), name: String, amount: Double, category: ExpenseCategory, note: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.note = note
    }
    
    var formattedAmount: String {
        amount.formattedCurrency
    }
}

// MARK: - Custom Category

struct CustomCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    
    init(id: UUID = UUID(), name: String, icon: String, colorHex: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
