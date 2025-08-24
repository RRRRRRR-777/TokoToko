import SwiftUI

struct ConsentView: View {
    let policy: Policy
    let onAgree: () -> Void
    let onDecline: () -> Void

    @State private var hasViewedPrivacyPolicy = false
    @State private var hasViewedTermsOfService = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false

    private var canAgree: Bool {
        hasViewedPrivacyPolicy && hasViewedTermsOfService
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("アプリのご利用にあたって")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    Text("TokoTokoをご利用いただくには、プライバシーポリシーと利用規約への同意が必要です。以下のリンクから内容をご確認ください。")
                        .font(.body)
                        .padding(.horizontal)

                    // プライバシーポリシーボタン
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        HStack {
                            Image(systemName: hasViewedPrivacyPolicy ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasViewedPrivacyPolicy ? .green : .gray)

                            Text("プライバシーポリシーを確認")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // 利用規約ボタン
                    Button(action: {
                        showingTermsOfService = true
                    }) {
                        HStack {
                            Image(systemName: hasViewedTermsOfService ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasViewedTermsOfService ? .green : .gray)

                            Text("利用規約を確認")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    if canAgree {
                        Text("✓ すべての内容を確認しました")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            // ボタンエリア
            HStack(spacing: 20) {
                Button(action: onDecline) {
                    Text("同意しない")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }

                Button(action: onAgree) {
                    Text("同意する")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAgree ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!canAgree)
            }
            .padding()
        }
        .navigationTitle("利用規約への同意")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                PolicyView(policy: policy, policyType: .privacyPolicy)
                    .navigationBarItems(trailing: Button("閉じる") {
                        showingPrivacyPolicy = false
                        hasViewedPrivacyPolicy = true
                    })
            }
        }
        .sheet(isPresented: $showingTermsOfService) {
            NavigationView {
                PolicyView(policy: policy, policyType: .termsOfService)
                    .navigationBarItems(trailing: Button("閉じる") {
                        showingTermsOfService = false
                        hasViewedTermsOfService = true
                    })
            }
        }
        .background(Color("BackgroundColor"))
    }
}

#if DEBUG
struct ConsentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConsentView(
                policy: Policy(
                    version: "1.0.0",
                    privacyPolicy: LocalizedContent(
                        ja: "プライバシーポリシー本文...",
                        en: nil
                    ),
                    termsOfService: LocalizedContent(
                        ja: "利用規約本文...",
                        en: nil
                    ),
                    updatedAt: Date(),
                    effectiveDate: Date()
                ),
                onAgree: {
                    print("同意されました")
                },
                onDecline: {
                    print("同意されませんでした")
                }
            )
        }
    }
}
#endif
