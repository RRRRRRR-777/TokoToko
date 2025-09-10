import SwiftUI
import UIKit

enum PolicyType {
    case privacyPolicy
    case termsOfService

    var title: String {
        switch self {
        case .privacyPolicy:
            return "プライバシーポリシー"
        case .termsOfService:
            return "利用規約"
        }
    }
}

struct PolicyView: View {
    let policy: Policy
    let policyType: PolicyType

    private var policyText: String {
        switch policyType {
        case .privacyPolicy:
            return policy.privacyPolicy.ja
        case .termsOfService:
            return policy.termsOfService.ja
        }
    }

    static func configureNavigationBarAppearance() {
        // ポリシー画面用の特殊設定（シャドウ非表示）を適用
        NavigationBarStyleManager.shared.applyUnifiedStyle(customizations: .policyScreen)
    }

    var body: some View {
        ZStack {
            // 画面全体の背景色（両端の黒い部分も含めて完全にカバー）
            Color("BackgroundColor")
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(policyText)
                        .font(.body)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .multilineTextAlignment(.leading)

                    Text("最終更新日: \(policy.updatedAt, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)

                    Text("バージョン: \(policy.version)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.bottom)
                }
                .padding(.top)
            }
        }
        .navigationTitle(policyType.title)
        .navigationBarTitleDisplayMode(.large)
        .accentColor(.black)
        .onAppear {
            Self.configureNavigationBarAppearance()
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }
}

#if DEBUG
struct PolicyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                PolicyView(
                    policy: Policy(
                        version: "1.0.0",
                        privacyPolicy: LocalizedContent(
                            ja: "このアプリケーションは、利用者のプライバシーを尊重し、個人情報の保護に努めます。\n\n1. 収集する情報\n- 位置情報\n- 写真データ\n- ユーザープロフィール情報\n\n2. 情報の利用目的\n- サービスの提供\n- サービスの改善\n- ユーザーサポート",
                            en: nil
                        ),
                        termsOfService: LocalizedContent(
                            ja: "本利用規約は、てくとこアプリの利用条件を定めるものです。",
                            en: nil
                        ),
                        updatedAt: Date(),
                        effectiveDate: Date()
                    ),
                    policyType: .privacyPolicy
                )
            }
            .previewDisplayName("プライバシーポリシー")
            .onAppear {
                PolicyView.configureNavigationBarAppearance()
            }

            NavigationView {
                PolicyView(
                    policy: Policy(
                        version: "1.0.0",
                        privacyPolicy: LocalizedContent(
                            ja: "このアプリケーションは、利用者のプライバシーを尊重し、個人情報の保護に努めます。",
                            en: nil
                        ),
                        termsOfService: LocalizedContent(
                            ja: "本利用規約は、てくとこアプリの利用条件を定めるものです。\n\n第1条（適用）\n本利用規約は、ユーザーが本アプリを利用する際の条件を定めたものです。\n\n第2条（利用規約の変更）\n当社は、必要と判断した場合には、ユーザーに通知することなくいつでも本利用規約を変更することができるものとします。\n\n第3条（プライバシー）\n当社は、ユーザーの個人情報を適切に管理し、第三者に開示することはありません。\n\n第4条（禁止事項）\nユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。\n- 法令または公序良俗に違反する行為\n- 犯罪行為に関連する行為\n- 本アプリの運営を妨害する行為",
                            en: nil
                        ),
                        updatedAt: Date(),
                        effectiveDate: Date()
                    ),
                    policyType: .termsOfService
                )
            }
            .previewDisplayName("利用規約")
            .onAppear {
                PolicyView.configureNavigationBarAppearance()
            }
        }
    }
}
#endif
