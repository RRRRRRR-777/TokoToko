import SwiftUI

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(policyText)
                    .font(.body)
                    .padding(.horizontal)

                Text("最終更新日: \(policy.updatedAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                Text("バージョン: \(policy.version)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .padding(.top)
        }
        .navigationTitle(policyType.title)
        .navigationBarTitleDisplayMode(.large)
        .background(Color("BackgroundColor"))
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
        NavigationView {
            PolicyView(
                policy: Policy(
                    version: "1.0.0",
                    privacyPolicy: LocalizedContent(
                        ja: "このアプリケーションは、利用者のプライバシーを尊重し、個人情報の保護に努めます。\n\n1. 収集する情報\n- 位置情報\n- 写真データ\n- ユーザープロフィール情報\n\n2. 情報の利用目的\n- サービスの提供\n- サービスの改善\n- ユーザーサポート",
                        en: nil
                    ),
                    termsOfService: LocalizedContent(
                        ja: "本利用規約は、TokoTokoアプリの利用条件を定めるものです。",
                        en: nil
                    ),
                    updatedAt: Date(),
                    effectiveDate: Date()
                ),
                policyType: .privacyPolicy
            )
        }
    }
}
#endif
