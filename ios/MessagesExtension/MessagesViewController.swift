import Messages
import UIKit

final class MessagesViewController: MSMessagesAppViewController, UITextFieldDelegate {
  private enum Mode: Int {
    case compose = 0
    case preview = 1
  }

  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private let contentStack = UIStackView()
  private let modeControl = UISegmentedControl(items: ["Compose", "Preview"])

  private let titleField = UITextField()
  private let organizerField = UITextField()
  private let participantsField = UITextField()

  private let composeCard = UIView()
  private let previewCard = UIView()
  private let previewImageView = UIImageView()
  private let previewTitleLabel = UILabel()
  private let previewMetaLabel = UILabel()
  private let previewParticipantsLabel = UILabel()
  private let previewNoteLabel = UILabel()
  private let previewHintLabel = UILabel()

  private let statusLabel = UILabel()
  private let insertButton = UIButton(type: .system)
  private let openButton = UIButton(type: .system)
  private let dismissKeyboardButton = UIButton(type: .system)

  private var hasSelectedDraftMessage = false
  private var currentDraft = PlanningDraft(
    title: "Dinner plan",
    organizer: "Maya",
    participants: ["Maya", "Jordan", "Ari"],
    prompt: "Find the best overlap, then finish the plan in the full board."
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
    applyDraft(currentDraft, preferPreview: false)
    setStatus("Create a draft right in chat, then share it without leaving Messages.")
  }

  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)
    loadDraftIfNeeded(from: conversation.selectedMessage)
  }

  override func didSelect(_ message: MSMessage, conversation: MSConversation) {
    super.didSelect(message, conversation: conversation)
    loadDraftIfNeeded(from: message)
  }

  override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
    super.didTransition(to: presentationStyle)
    if presentationStyle == .compact {
      view.endEditing(true)
    }
  }

  private func configureView() {
    view.backgroundColor = .systemGroupedBackground

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    view.addGestureRecognizer(tapGesture)

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.keyboardDismissMode = .interactive
    view.addSubview(scrollView)

    contentView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentView)

    contentStack.axis = .vertical
    contentStack.spacing = 14
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(contentStack)

    modeControl.selectedSegmentIndex = Mode.compose.rawValue
    modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

    let header = headerView()
    let composeContent = composeSection()
    let previewContent = previewSection()
    let actionRow = actionButtonsRow()

    statusLabel.font = .preferredFont(forTextStyle: .subheadline)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0

    contentStack.addArrangedSubview(header)
    contentStack.addArrangedSubview(modeControl)
    contentStack.addArrangedSubview(composeContent)
    contentStack.addArrangedSubview(previewContent)
    contentStack.addArrangedSubview(statusLabel)
    contentStack.addArrangedSubview(actionRow)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
      contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
    ])

    updateVisibleSection()
  }

  private func headerView() -> UIView {
    let eyebrow = UILabel()
    eyebrow.font = .preferredFont(forTextStyle: .caption1)
    eyebrow.textColor = .systemBlue
    eyebrow.text = "iMessage Planning"

    let title = UILabel()
    title.font = .preferredFont(forTextStyle: .title2)
    title.textColor = .label
    title.numberOfLines = 0
    title.text = "Create and review the planning card directly inside Messages."

    let detail = UILabel()
    detail.font = .preferredFont(forTextStyle: .body)
    detail.textColor = .secondaryLabel
    detail.numberOfLines = 0
    detail.text = "The full Flutter app is still there when you need the full availability board, but the draft should feel useful in chat on its own."

    let stack = UIStackView(arrangedSubviews: [eyebrow, title, detail])
    stack.axis = .vertical
    stack.spacing = 6
    return stack
  }

  private func composeSection() -> UIView {
    composeCard.backgroundColor = .secondarySystemGroupedBackground
    composeCard.layer.cornerRadius = 24
    composeCard.layer.cornerCurve = .continuous

    let titleLabel = sectionLabel("Plan title")
    let organizerLabel = sectionLabel("Organizer")
    let participantsLabel = sectionLabel("Participants")

    titleField.placeholder = "Game night"
    organizerField.placeholder = "Who is kicking this off?"
    participantsField.placeholder = "Maya, Jordan, Ari"

    configureField(titleField, returnKeyType: .next)
    configureField(organizerField, returnKeyType: .next)
    configureField(participantsField, returnKeyType: .done)
    participantsField.autocapitalizationType = .sentences

    dismissKeyboardButton.configuration = tintedConfiguration(
      title: "Done Typing",
      image: UIImage(systemName: "keyboard.chevron.compact.down")
    )
    dismissKeyboardButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)

    let helper = UILabel()
    helper.font = .preferredFont(forTextStyle: .subheadline)
    helper.textColor = .secondaryLabel
    helper.numberOfLines = 0
    helper.text = "You can insert this card into the thread and still stay inside Messages to review it."

    let stack = UIStackView(
      arrangedSubviews: [
        titleLabel,
        titleField,
        organizerLabel,
        organizerField,
        participantsLabel,
        participantsField,
        helper,
        dismissKeyboardButton,
      ]
    )
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    composeCard.addSubview(stack)

    NSLayoutConstraint.activate([
      titleField.heightAnchor.constraint(equalToConstant: 46),
      organizerField.heightAnchor.constraint(equalToConstant: 46),
      participantsField.heightAnchor.constraint(equalToConstant: 46),
      stack.topAnchor.constraint(equalTo: composeCard.topAnchor, constant: 18),
      stack.leadingAnchor.constraint(equalTo: composeCard.leadingAnchor, constant: 18),
      stack.trailingAnchor.constraint(equalTo: composeCard.trailingAnchor, constant: -18),
      stack.bottomAnchor.constraint(equalTo: composeCard.bottomAnchor, constant: -18),
    ])

    return composeCard
  }

  private func previewSection() -> UIView {
    previewCard.backgroundColor = .secondarySystemGroupedBackground
    previewCard.layer.cornerRadius = 24
    previewCard.layer.cornerCurve = .continuous

    previewImageView.translatesAutoresizingMaskIntoConstraints = false
    previewImageView.layer.cornerRadius = 20
    previewImageView.layer.cornerCurve = .continuous
    previewImageView.clipsToBounds = true
    previewImageView.contentMode = .scaleAspectFill

    previewTitleLabel.font = .preferredFont(forTextStyle: .title3)
    previewTitleLabel.textColor = .label
    previewTitleLabel.numberOfLines = 0

    previewMetaLabel.font = .preferredFont(forTextStyle: .headline)
    previewMetaLabel.textColor = .systemBlue
    previewMetaLabel.numberOfLines = 0

    previewParticipantsLabel.font = .preferredFont(forTextStyle: .body)
    previewParticipantsLabel.textColor = .label
    previewParticipantsLabel.numberOfLines = 0

    previewNoteLabel.font = .preferredFont(forTextStyle: .body)
    previewNoteLabel.textColor = .secondaryLabel
    previewNoteLabel.numberOfLines = 0
    previewNoteLabel.text =
      "This view is the in-Messages version of the plan. People can read the draft here, share an updated card, and only open the app when they want the full availability board."

    previewHintLabel.font = .preferredFont(forTextStyle: .subheadline)
    previewHintLabel.textColor = .secondaryLabel
    previewHintLabel.numberOfLines = 0

    let eyebrow = sectionLabel("Live Messages Preview")
    let stack = UIStackView(
      arrangedSubviews: [
        eyebrow,
        previewImageView,
        previewTitleLabel,
        previewMetaLabel,
        previewParticipantsLabel,
        previewNoteLabel,
        previewHintLabel,
      ]
    )
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    previewCard.addSubview(stack)

    NSLayoutConstraint.activate([
      previewImageView.heightAnchor.constraint(equalToConstant: 180),
      stack.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 18),
      stack.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 18),
      stack.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -18),
      stack.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -18),
    ])

    return previewCard
  }

  private func actionButtonsRow() -> UIView {
    insertButton.configuration = filledConfiguration(
      title: "Insert Planning Card",
      image: UIImage(systemName: "plus.bubble.fill")
    )
    insertButton.addTarget(self, action: #selector(insertPlanningCard), for: .touchUpInside)

    openButton.configuration = tintedConfiguration(
      title: "Open Full Planner",
      image: UIImage(systemName: "arrow.up.forward.app")
    )
    openButton.addTarget(self, action: #selector(openPlanner), for: .touchUpInside)

    let buttonRow = UIStackView(arrangedSubviews: [insertButton, openButton])
    buttonRow.axis = .horizontal
    buttonRow.spacing = 12
    buttonRow.distribution = .fillEqually
    return buttonRow
  }

  private func configureField(_ field: UITextField, returnKeyType: UIReturnKeyType) {
    field.borderStyle = .roundedRect
    field.backgroundColor = .tertiarySystemBackground
    field.autocapitalizationType = .words
    field.returnKeyType = returnKeyType
    field.clearButtonMode = .whileEditing
    field.delegate = self
    field.inputAccessoryView = keyboardAccessoryToolbar()
  }

  private func sectionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.text = text
    return label
  }

  private func keyboardAccessoryToolbar() -> UIToolbar {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()
    let flexible = UIBarButtonItem(systemItem: .flexibleSpace)
    let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
    toolbar.items = [flexible, done]
    return toolbar
  }

  private func filledConfiguration(title: String, image: UIImage?) -> UIButton.Configuration {
    var configuration = UIButton.Configuration.filled()
    configuration.baseBackgroundColor = .systemBlue
    configuration.baseForegroundColor = .white
    configuration.cornerStyle = .large
    configuration.image = image
    configuration.imagePadding = 8
    configuration.title = title
    return configuration
  }

  private func tintedConfiguration(title: String, image: UIImage?) -> UIButton.Configuration {
    var configuration = UIButton.Configuration.tinted()
    configuration.baseBackgroundColor = .systemBlue.withAlphaComponent(0.12)
    configuration.baseForegroundColor = .systemBlue
    configuration.cornerStyle = .large
    configuration.image = image
    configuration.imagePadding = 8
    configuration.title = title
    return configuration
  }

  private func loadDraftIfNeeded(from message: MSMessage?) {
    guard let draft = PlanningDraft(url: message?.url) else {
      hasSelectedDraftMessage = false
      updateInsertButtonTitle()
      setStatus("Create a draft in chat, then insert it into the thread without leaving Messages.")
      return
    }

    hasSelectedDraftMessage = true
    applyDraft(draft, preferPreview: true)
    setStatus("This planning card now opens directly inside Messages. The full app is optional.")
  }

  private func applyDraft(_ draft: PlanningDraft, preferPreview: Bool) {
    currentDraft = draft
    titleField.text = draft.title
    organizerField.text = draft.organizer
    participantsField.text = draft.participants.joined(separator: ", ")
    refreshPreview(with: draft)
    if preferPreview {
      modeControl.selectedSegmentIndex = Mode.preview.rawValue
    }
    updateInsertButtonTitle()
    updateVisibleSection()
  }

  private func refreshPreview(with draft: PlanningDraft) {
    previewImageView.image = draft.previewImage()
    previewTitleLabel.text = draft.title
    previewMetaLabel.text = "Organizer: \(draft.organizer) • \(draft.participants.count) people"
    previewParticipantsLabel.text = "Participants: \(draft.participants.joined(separator: ", "))"
    previewHintLabel.text = hasSelectedDraftMessage
      ? "You are looking at a draft that already exists in this thread. You can keep it in Messages, update it here, or open the full planner."
      : "This is exactly what the planning draft will look like inside Messages once you insert it."
  }

  private func updateInsertButtonTitle() {
    let title = hasSelectedDraftMessage ? "Update Planning Card" : "Insert Planning Card"
    insertButton.configuration = filledConfiguration(
      title: title,
      image: UIImage(systemName: hasSelectedDraftMessage ? "bubble.left.and.text.bubble.right.fill" : "plus.bubble.fill")
    )
  }

  private func updateVisibleSection() {
    let mode = Mode(rawValue: modeControl.selectedSegmentIndex) ?? .compose
    composeCard.isHidden = mode != .compose
    previewCard.isHidden = mode != .preview
  }

  private func setStatus(_ text: String) {
    statusLabel.text = text
  }

  private func makeDraftFromFields() -> PlanningDraft {
    let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    let organizer = organizerField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    let participants = (participantsField.text ?? "")
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    return PlanningDraft(
      title: title?.isEmpty == false ? title! : "New plan",
      organizer: organizer?.isEmpty == false ? organizer! : "Organizer",
      participants: participants.isEmpty ? ["Organizer"] : participants,
      prompt: currentDraft.prompt
    )
  }

  @objc
  private func modeChanged() {
    updateVisibleSection()
    if modeControl.selectedSegmentIndex == Mode.preview.rawValue {
      view.endEditing(true)
    }
  }

  @objc
  private func dismissKeyboard() {
    view.endEditing(true)
  }

  @objc
  private func insertPlanningCard() {
    guard let conversation = activeConversation else {
      setStatus("Messages is not ready yet. Try again in a second.")
      return
    }

    dismissKeyboard()
    let draft = makeDraftFromFields()
    currentDraft = draft
    refreshPreview(with: draft)

    let message = MSMessage(session: conversation.selectedMessage?.session ?? MSSession())
    message.url = draft.url
    message.layout = draft.messageLayout()
    message.summaryText = "Planning draft: \(draft.title)"

    conversation.insert(message) { [weak self] error in
      guard let self else { return }
      if let error {
        self.setStatus("Could not insert the planning card: \(error.localizedDescription)")
        return
      }

      self.hasSelectedDraftMessage = true
      self.updateInsertButtonTitle()
      self.modeControl.selectedSegmentIndex = Mode.preview.rawValue
      self.updateVisibleSection()
      self.setStatus("Planning card shared. People can review it directly in Messages or open the full planner if they want more.")
    }
  }

  @objc
  private func openPlanner() {
    dismissKeyboard()
    let draft = makeDraftFromFields()
    currentDraft = draft
    refreshPreview(with: draft)

    extensionContext?.open(draft.url) { [weak self] success in
      self?.setStatus(
        success
          ? "Opening Chat Utilities Hub..."
          : "Could not open the full planner. Make sure the app is installed."
      )
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    switch textField {
    case titleField:
      organizerField.becomeFirstResponder()
    case organizerField:
      participantsField.becomeFirstResponder()
    default:
      dismissKeyboard()
    }
    return true
  }
}

private struct PlanningDraft {
  let title: String
  let organizer: String
  let participants: [String]
  let prompt: String

  init(title: String, organizer: String, participants: [String], prompt: String) {
    self.title = title
    self.organizer = organizer
    self.participants = participants
    self.prompt = prompt
  }

  init?(url: URL?) {
    guard
      let url,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      components.scheme == "chatutilitieshub",
      components.host == "compose"
    else {
      return nil
    }

    let queryItems = components.queryItems ?? []
    let title = queryItems.first(where: { $0.name == "title" })?.value ?? "New plan"
    let organizer = queryItems.first(where: { $0.name == "createdBy" })?.value ?? "Organizer"
    let prompt =
      queryItems.first(where: { $0.name == "prompt" })?.value ??
      "Find the best overlap, then finish the plan in the full board."
    let participants = (queryItems.first(where: { $0.name == "participants" })?.value ?? "")
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    self.init(
      title: title,
      organizer: organizer,
      participants: participants.isEmpty ? [organizer] : participants,
      prompt: prompt
    )
  }

  var url: URL {
    var components = URLComponents()
    components.scheme = "chatutilitieshub"
    components.host = "compose"
    components.queryItems = [
      URLQueryItem(name: "title", value: title),
      URLQueryItem(name: "prompt", value: prompt),
      URLQueryItem(name: "createdBy", value: organizer),
      URLQueryItem(name: "participants", value: participants.joined(separator: ",")),
    ]
    return components.url!
  }

  func messageLayout() -> MSMessageTemplateLayout {
    let layout = MSMessageTemplateLayout()
    layout.caption = title
    layout.subcaption = organizer
    layout.trailingCaption = "\(participants.count) people"
    layout.trailingSubcaption = "View in Messages"
    layout.image = previewImage()
    return layout
  }

  func previewImage() -> UIImage {
    let size = CGSize(width: 720, height: 420)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      let bounds = CGRect(origin: .zero, size: size)
      let cgContext = context.cgContext

      let colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor] as CFArray
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
      cgContext.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: size.width, y: size.height),
        options: []
      )

      let cardRect = bounds.insetBy(dx: 28, dy: 28)
      let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 34)
      UIColor.white.withAlphaComponent(0.95).setFill()
      cardPath.fill()

      let badgeRect = CGRect(x: cardRect.minX + 24, y: cardRect.minY + 24, width: 182, height: 34)
      let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 17)
      UIColor.systemBlue.withAlphaComponent(0.12).setFill()
      badgePath.fill()
      NSString(string: "Planning Draft").draw(
        in: badgeRect.insetBy(dx: 14, dy: 8),
        withAttributes: [
          .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
          .foregroundColor: UIColor.systemBlue,
        ]
      )

      NSString(string: title).draw(
        with: CGRect(x: cardRect.minX + 24, y: cardRect.minY + 78, width: cardRect.width - 48, height: 96),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [
          .font: UIFont.systemFont(ofSize: 36, weight: .bold),
          .foregroundColor: UIColor.label,
        ],
        context: nil
      )

      NSString(string: "Organizer: \(organizer)").draw(
        in: CGRect(x: cardRect.minX + 24, y: cardRect.minY + 180, width: cardRect.width - 48, height: 28),
        withAttributes: [
          .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
          .foregroundColor: UIColor.systemBlue,
        ]
      )

      NSString(string: participantsSummary).draw(
        with: CGRect(x: cardRect.minX + 24, y: cardRect.minY + 218, width: cardRect.width - 48, height: 78),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [
          .font: UIFont.systemFont(ofSize: 21, weight: .regular),
          .foregroundColor: UIColor.darkGray,
        ],
        context: nil
      )

      let footerRect = CGRect(x: cardRect.minX + 24, y: cardRect.maxY - 74, width: cardRect.width - 48, height: 46)
      let footerPath = UIBezierPath(roundedRect: footerRect, cornerRadius: 20)
      UIColor.systemGray6.setFill()
      footerPath.fill()
      NSString(string: "Open directly in Messages, or jump into the full planner.").draw(
        with: footerRect.insetBy(dx: 16, dy: 10),
        options: [.usesLineFragmentOrigin],
        attributes: [
          .font: UIFont.systemFont(ofSize: 18, weight: .medium),
          .foregroundColor: UIColor.secondaryLabel,
        ],
        context: nil
      )
    }
  }

  private var participantsSummary: String {
    let visibleNames = participants.prefix(4).joined(separator: ", ")
    if participants.count <= 4 {
      return "Participants: \(visibleNames)"
    }
    return "Participants: \(visibleNames) +\(participants.count - 4) more"
  }
}
