import SwiftUI

// MARK: - AutomaticPreferenceKey

private protocol AutomaticPreferenceKey: PreferenceKey {}

extension AutomaticPreferenceKey {
  internal static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}

// MARK: - PageSheet

public enum PageSheet {
  /// An object that represents a height where a sheet naturally rests.
  public typealias Detent = UISheetPresentationController.Detent

  /// An object that represents an array of heights where a sheet can naturally rest.
  public typealias Detents = [Detent]

  // MARK: - Configuration

  fileprivate struct Configuration {
    var prefersGrabberVisible: Bool = false
    var detents: Detents = [.large()]
    var largestUndimmedDetentIdentifier: Detent.Identifier? = nil
    var selectedDetentIdentifier: Detent.Identifier? = nil
    var prefersEdgeAttachedInCompactHeight: Bool = false
    var widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = false
    var prefersScrollingExpandsWhenScrolledToEdge: Bool = true
    var preferredCornerRadius: CGFloat? = nil

    static var `default`: Self { .init() }
  }

  // MARK: - ConfiguredHostingView

  internal struct ConfiguredHostingView<Content: View>: View {

    @State
    private var configuration: Configuration = .default

    @State
    private var selectedDetent: Detent.Identifier?

    let content: Content

    var body: some View {
      HostingView(configuration: $configuration, selectedDetent: $selectedDetent, content: content)
        .onChange(of: selectedDetent) { newValue in
          self.configuration.selectedDetentIdentifier = newValue
        }
        .onPreferenceChange(Preference.SelectedDetentIdentifier.self) { newValue in
          self.selectedDetent = newValue
        }
        .onPreferenceChange(Preference.GrabberVisible.self) { newValue in
          self.configuration.prefersGrabberVisible = newValue
        }
        .onPreferenceChange(Preference.Detents.self) { newValue in
          self.configuration.detents = newValue
        }
        .onPreferenceChange(Preference.LargestUndimmedDetentIdentifier.self) { newValue in
          self.configuration.largestUndimmedDetentIdentifier = newValue
        }
        .onPreferenceChange(Preference.EdgeAttachedInCompactHeight.self) { newValue in
          self.configuration.prefersEdgeAttachedInCompactHeight = newValue
        }
        .onPreferenceChange(Preference.WidthFollowsPreferredContentSizeWhenEdgeAttached.self) {
          newValue in
          self.configuration.widthFollowsPreferredContentSizeWhenEdgeAttached = newValue
        }
        .onPreferenceChange(Preference.ScrollingExpandsWhenScrolledToEdge.self) { newValue in
          self.configuration.prefersScrollingExpandsWhenScrolledToEdge = newValue
        }
        .onPreferenceChange(Preference.CornerRadius.self) { newValue in
          self.configuration.preferredCornerRadius = newValue
        }
        .ignoresSafeArea()
        .environment(\._selectedDetentIdentifier, self.selectedDetent)
    }
  }

  // MARK: - HostingController

  fileprivate class HostingController<Content: View>: UIHostingController<Content>,
    UISheetPresentationControllerDelegate
  {
    var configuration: Configuration = .default {
      didSet {
        if let sheet = self.sheetPresentationController {
          if sheet.delegate == nil {
            sheet.delegate = self
          }

          let config = self.configuration
          sheet.animateChanges {
            sheet.prefersGrabberVisible = config.prefersGrabberVisible
            sheet.detents = config.detents
            sheet.largestUndimmedDetentIdentifier = config.largestUndimmedDetentIdentifier
            sheet.prefersEdgeAttachedInCompactHeight = config.prefersEdgeAttachedInCompactHeight
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached =
              config.widthFollowsPreferredContentSizeWhenEdgeAttached
            sheet.prefersScrollingExpandsWhenScrolledToEdge =
              config.prefersScrollingExpandsWhenScrolledToEdge
            sheet.preferredCornerRadius = config.preferredCornerRadius
            sheet.selectedDetentIdentifier = config.selectedDetentIdentifier
          }
        }
      }
    }

    @Binding
    var selectedDetent: Detent.Identifier?

    init(rootView: Content, selectedDetent: Binding<Detent.Identifier?>) {
      self._selectedDetent = selectedDetent
      super.init(rootView: rootView)
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    // MARK: UISheetPresentationControllerDelegate

    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
      _ sheet: UISheetPresentationController
    ) {
      self.selectedDetent = sheet.selectedDetentIdentifier
    }
  }

  // MARK: - HostingView

  fileprivate struct HostingView<Content: View>: UIViewControllerRepresentable {
    @Binding
    var configuration: Configuration

    @Binding
    var selectedDetent: Detent.Identifier?

    @State
    private var selectedDetentIdentifier: Detent.Identifier?

    let content: Content

    func makeUIViewController(context: Context) -> HostingController<Content> {
      HostingController(
        rootView: content,
        selectedDetent: $selectedDetent
      )
    }

    func updateUIViewController(_ controller: HostingController<Content>, context: Context) {
      controller.configuration = configuration
      controller.rootView = content
    }
  }
}

// MARK: - Presentation View Modifiers

extension PageSheet {

  internal enum Modifier {

    // MARK: Presentation

    struct BooleanPresentation<SheetContent: View>: ViewModifier {

      @Binding
      var isPresented: Bool

      let onDismiss: (() -> Void)?
      let content: () -> SheetContent

      func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
          ConfiguredHostingView(
            content: self.content()
          )
        }
      }
    }

    // MARK: ItemPresentation

    struct ItemPresentation<Item: Identifiable, SheetContent: View>: ViewModifier {

      @Binding
      var item: Item?

      let onDismiss: (() -> Void)?
      let content: (Item) -> SheetContent

      func body(content: Content) -> some View {
        content.sheet(item: $item, onDismiss: onDismiss) { item in
          ConfiguredHostingView(
            content: self.content(item)
          )
        }
      }
    }
  }

}

// MARK: Preferences

extension PageSheet {
  internal enum Preference {
    struct GrabberVisible: AutomaticPreferenceKey {
      static var defaultValue: Bool = Configuration.default.prefersGrabberVisible
    }

    struct Detents: AutomaticPreferenceKey {
      static var defaultValue: PageSheet.Detents = Configuration.default.detents
    }

    struct LargestUndimmedDetentIdentifier: AutomaticPreferenceKey {
      static var defaultValue: Detent.Identifier? = Configuration.default
        .largestUndimmedDetentIdentifier
    }

    struct SelectedDetentIdentifier: AutomaticPreferenceKey {
      static var defaultValue: Detent.Identifier? = Configuration.default.selectedDetentIdentifier
    }

    struct EdgeAttachedInCompactHeight: AutomaticPreferenceKey {
      static var defaultValue: Bool = Configuration.default.prefersEdgeAttachedInCompactHeight
    }

    struct WidthFollowsPreferredContentSizeWhenEdgeAttached: AutomaticPreferenceKey {
      static var defaultValue: Bool = Configuration.default
        .widthFollowsPreferredContentSizeWhenEdgeAttached
    }

    struct ScrollingExpandsWhenScrolledToEdge: AutomaticPreferenceKey {
      static var defaultValue: Bool = Configuration.default
        .prefersScrollingExpandsWhenScrolledToEdge
    }

    struct CornerRadius: AutomaticPreferenceKey {
      static var defaultValue: CGFloat? = Configuration.default.preferredCornerRadius
    }
  }
}
