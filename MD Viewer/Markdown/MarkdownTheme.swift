import SwiftUI
import MarkdownUI

extension Theme {
    static let obsidian = Theme()
        .text {
            ForegroundColor(.obsidianText)
            BackgroundColor(nil)
            FontSize(16)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.88))
            ForegroundColor(.obsidianInlineCodeText)
            BackgroundColor(.obsidianInlineCodeBackground)
        }
        .strong { FontWeight(.semibold) }
        .emphasis { FontStyle(.italic) }
        .strikethrough { StrikethroughStyle(.single) }
        .link { ForegroundColor(.obsidianLink) }
        .heading1 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 28, bottom: 14)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.85))
                }
        }
        .heading2 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 12)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.5))
                }
        }
        .heading3 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 22, bottom: 10)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.25))
                }
        }
        .heading4 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 20, bottom: 8)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.1))
                }
        }
        .heading5 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 18, bottom: 6)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.0))
                    ForegroundColor(.obsidianSecondaryText)
                }
        }
        .heading6 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 18, bottom: 6)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(0.9))
                    ForegroundColor(.obsidianTertiaryText)
                }
        }
        .paragraph { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .relativeLineSpacing(.em(0.4))
                .markdownMargin(top: 0, bottom: 14)
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.obsidianAccent)
                    .relativeFrame(width: .em(0.22))
                configuration.label
                    .markdownTextStyle { ForegroundColor(.obsidianSecondaryText) }
                    .relativePadding(.horizontal, length: .em(1))
            }
            .fixedSize(horizontal: false, vertical: true)
            .markdownMargin(top: 0, bottom: 14)
        }
        .codeBlock { configuration in
            switch configuration.language?.lowercased() {
            case "mermaid":
                MermaidBlockView(source: configuration.content)
                    .markdownMargin(top: 4, bottom: 16)
            case "math":
                MathBlockView(source: configuration.content)
                    .markdownMargin(top: 4, bottom: 16)
            default:
                ScrollView(.horizontal) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .relativeLineSpacing(.em(0.3))
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                        }
                        .padding(14)
                }
                .background(Color.obsidianCodeBlockBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .markdownMargin(top: 4, bottom: 16)
            }
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.25))
        }
        .taskListMarker { configuration in
            Image(systemName: configuration.isCompleted ? "checkmark.square.fill" : "square")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.obsidianAccent, Color.obsidianBorder)
                .imageScale(.small)
                .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
        }
        .table { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .markdownTableBorderStyle(.init(color: .obsidianBorder))
                .markdownMargin(top: 0, bottom: 16)
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    if configuration.row == 0 { FontWeight(.semibold) }
                    BackgroundColor(nil)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 6)
                .padding(.horizontal, 13)
                .relativeLineSpacing(.em(0.25))
        }
        .thematicBreak {
            Divider()
                .overlay(Color.obsidianBorder)
                .markdownMargin(top: 22, bottom: 22)
        }
}

private extension Color {
    static let obsidianText = Color(
        light: Color(rgba: 0x2e34_40ff), dark: Color(rgba: 0xdcdd_deff)
    )
    static let obsidianSecondaryText = Color(
        light: Color(rgba: 0x6b73_80ff), dark: Color(rgba: 0xa3a4_a6ff)
    )
    static let obsidianTertiaryText = Color(
        light: Color(rgba: 0x8a91_9eff), dark: Color(rgba: 0x7a7c_82ff)
    )
    static let obsidianBackground = Color(
        light: .white, dark: Color(rgba: 0x1e1e_1eff)
    )
    static let obsidianInlineCodeText = Color(
        light: Color(rgba: 0xc7254eff), dark: Color(rgba: 0xff7eb6ff)
    )
    static let obsidianInlineCodeBackground = Color(
        light: Color(rgba: 0xf3f4_f6ff), dark: Color(rgba: 0x2a2a_2aff)
    )
    static let obsidianCodeBlockBackground = Color(
        light: Color(rgba: 0xf6f7_f9ff), dark: Color(rgba: 0x262626ff)
    )
    static let obsidianLink = Color(
        light: Color(rgba: 0x7c4dffff), dark: Color(rgba: 0xa78bfaff)
    )
    static let obsidianAccent = Color(
        light: Color(rgba: 0x8b7cf6ff), dark: Color(rgba: 0xa78bfaff)
    )
    static let obsidianBorder = Color(
        light: Color(rgba: 0xe5e7_ebff), dark: Color(rgba: 0x3a3a_3aff)
    )
}
