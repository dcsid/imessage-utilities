import Messages
import UIKit

final class MessagesViewController: MSMessagesAppViewController, UITextFieldDelegate {
  private enum Mode: Int {
    case compose = 0
    case preview = 1
  }

  private let compactCard = UIView()
  private let compactTitleLabel = UILabel()
  private let compactDetailLabel = UILabel()
  private let compactButton = UIButton(type: .system)

  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private let contentStack = UIStackView()
  private let modeControl = UISegmentedControl(items: ["Compose", "Preview"])

  private let titleField = UITextField()
  private let organizerField = UITextField()
  private let availabilityWindowLabel = UILabel()
  private let availabilitySummaryLabel = UILabel()
  private let availabilityGridContainer = UIStackView()
  private let gridTimeColumnWidth: CGFloat = 54
  private let gridDayColumnWidth: CGFloat = 38
  private let gridCellHeight: CGFloat = 22

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
  private var hasRequestedExpansion = false
  private var availabilityButtons: [String: UIButton] = [:]
  private var dragSelectionMode: Bool?
  private var draggedSlotIds = Set<String>()

  private var hasSelectedDraftMessage = false
  private var currentDraft = PlanningDraft(
    title: "Availability board",
    organizer: "Maya",
    participants: [],
    board: AvailabilityBoard(),
    prompt: "Collect availability first, then lock the best overlap in the full board."
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
    applyDraft(currentDraft, preferPreview: false)
    setStatus("Tap the in-Messages availability grid, then share the board back into the thread.")
  }

  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)
    loadDraftIfNeeded(from: conversation.selectedMessage)
    ensureExpandedPresentation()
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
    updateVisibleSection()
  }

  private func configureView() {
    view.backgroundColor = .systemGroupedBackground

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    view.addGestureRecognizer(tapGesture)

    compactCard.translatesAutoresizingMaskIntoConstraints = false
    compactCard.backgroundColor = .secondarySystemGroupedBackground
    compactCard.layer.cornerRadius = 24
    compactCard.layer.cornerCurve = .continuous
    view.addSubview(compactCard)

    compactTitleLabel.font = .preferredFont(forTextStyle: .headline)
    compactTitleLabel.textColor = .label
    compactTitleLabel.numberOfLines = 0
    compactTitleLabel.text = "Open the When2Meet board in Messages."

    compactDetailLabel.font = .preferredFont(forTextStyle: .subheadline)
    compactDetailLabel.textColor = .secondaryLabel
    compactDetailLabel.numberOfLines = 0
    compactDetailLabel.text = "Use the availability grid right here in chat. Everyone in the thread can join later by responding."

    compactButton.configuration = filledConfiguration(
      title: "Open When2Meet Board",
      image: UIImage(systemName: "calendar.badge.plus")
    )
    compactButton.addTarget(self, action: #selector(expandComposer), for: .touchUpInside)

    let compactStack = UIStackView(arrangedSubviews: [compactTitleLabel, compactDetailLabel, compactButton])
    compactStack.axis = .vertical
    compactStack.spacing = 12
    compactStack.translatesAutoresizingMaskIntoConstraints = false
    compactCard.addSubview(compactStack)

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
      compactCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      compactCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      compactCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      compactCard.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

      compactStack.topAnchor.constraint(equalTo: compactCard.topAnchor, constant: 16),
      compactStack.leadingAnchor.constraint(equalTo: compactCard.leadingAnchor, constant: 16),
      compactStack.trailingAnchor.constraint(equalTo: compactCard.trailingAnchor, constant: -16),
      compactStack.bottomAnchor.constraint(equalTo: compactCard.bottomAnchor, constant: -16),

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
    eyebrow.text = "iMessage Availability"

    let title = UILabel()
    title.font = .preferredFont(forTextStyle: .title2)
    title.textColor = .label
    title.numberOfLines = 0
    title.text = "Use the scheduling board directly inside Messages."

    let detail = UILabel()
    detail.font = .preferredFont(forTextStyle: .body)
    detail.textColor = .secondaryLabel
    detail.numberOfLines = 0
    detail.text = "The core When2Meet interaction should work here first. The Flutter app is only for the larger planning flow after the schedule is taking shape."

    let stack = UIStackView(arrangedSubviews: [eyebrow, title, detail])
    stack.axis = .vertical
    stack.spacing = 6
    return stack
  }

  private func composeSection() -> UIView {
    composeCard.backgroundColor = .secondarySystemGroupedBackground
    composeCard.layer.cornerRadius = 24
    composeCard.layer.cornerCurve = .continuous

    let titleLabel = sectionLabel("Availability title")
    let organizerLabel = sectionLabel("Organizer")
    let boardLabel = sectionLabel("When2Meet board")

    titleField.placeholder = "Spring launch availability"
    organizerField.placeholder = "Who is kicking this off?"

    configureField(titleField, returnKeyType: .next)
    configureField(organizerField, returnKeyType: .done)

    availabilityWindowLabel.font = .preferredFont(forTextStyle: .subheadline)
    availabilityWindowLabel.textColor = .systemBlue
    availabilityWindowLabel.numberOfLines = 0

    availabilitySummaryLabel.font = .preferredFont(forTextStyle: .body)
    availabilitySummaryLabel.textColor = .secondaryLabel
    availabilitySummaryLabel.numberOfLines = 0

    availabilityGridContainer.axis = .vertical
    availabilityGridContainer.spacing = 3
    availabilityGridContainer.backgroundColor = .white
    availabilityGridContainer.layer.cornerRadius = 18
    availabilityGridContainer.layer.cornerCurve = .continuous
    availabilityGridContainer.layer.borderWidth = 1
    availabilityGridContainer.layer.borderColor = UIColor.systemGray5.cgColor
    availabilityGridContainer.isLayoutMarginsRelativeArrangement = true
    availabilityGridContainer.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    availabilityGridContainer.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleAvailabilityPan(_:))))

    dismissKeyboardButton.configuration = tintedConfiguration(
      title: "Done Typing",
      image: UIImage(systemName: "keyboard.chevron.compact.down")
    )
    dismissKeyboardButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)

    let helper = UILabel()
    helper.font = .preferredFont(forTextStyle: .subheadline)
    helper.textColor = .secondaryLabel
    helper.numberOfLines = 0
    helper.text = "Drag across the board like When2Meet. Sweep over every time block that works for you."

    let stack = UIStackView(
      arrangedSubviews: [
        titleLabel,
        titleField,
        organizerLabel,
        organizerField,
        helper,
        boardLabel,
        availabilityWindowLabel,
        availabilitySummaryLabel,
        availabilityGridContainer,
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
      "This view is the in-Messages version of the board. People can read the draft here, share an updated card, and only open the app when they want the full availability grid."

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
      title: "Insert Availability Card",
      image: UIImage(systemName: "calendar.badge.plus")
    )
    insertButton.addTarget(self, action: #selector(insertPlanningCard), for: .touchUpInside)

    openButton.configuration = tintedConfiguration(
      title: "Open Full Board",
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
      setStatus("Create an availability draft in chat, then insert it into the thread. People will reopen the board and keep using the grid in Messages.")
      return
    }

    hasSelectedDraftMessage = true
    applyDraft(draft, preferPreview: false)
    setStatus("This availability board now opens directly inside Messages. Keep tapping the grid here, or jump into the full app later.")
  }

  private func applyDraft(_ draft: PlanningDraft, preferPreview: Bool) {
    currentDraft = draft
    titleField.text = draft.title
    organizerField.text = draft.organizer
    refreshAvailabilityComposer(with: draft)
    refreshPreview(with: draft)
    modeControl.selectedSegmentIndex = preferPreview ? Mode.preview.rawValue : Mode.compose.rawValue
    updateInsertButtonTitle()
    updateVisibleSection()
  }

  private func refreshPreview(with draft: PlanningDraft) {
    previewImageView.image = draft.previewImage()
    previewTitleLabel.text = draft.title
    previewMetaLabel.text = "Organizer: \(draft.organizer) • \(draft.board.selectedSlotIds.count) blocks selected"
    previewParticipantsLabel.text = draft.previewSummary
    previewHintLabel.text = hasSelectedDraftMessage
      ? "You are looking at a shared board that already exists in this thread. Reopen it here to keep editing the time grid in Messages."
      : "This is the card people in the thread will reopen to keep using the board in Messages."
  }

  private func updateInsertButtonTitle() {
    let title = hasSelectedDraftMessage ? "Update Availability Card" : "Insert Availability Card"
    insertButton.configuration = filledConfiguration(
      title: title,
      image: UIImage(systemName: hasSelectedDraftMessage ? "calendar.badge.clock" : "calendar.badge.plus")
    )
  }

  private func updateVisibleSection() {
    let mode = Mode(rawValue: modeControl.selectedSegmentIndex) ?? .compose
    let isCompact = presentationStyle == .compact
    compactCard.isHidden = !isCompact
    scrollView.isHidden = isCompact
    composeCard.isHidden = isCompact || mode != .compose
    previewCard.isHidden = isCompact || mode != .preview
  }

  private func setStatus(_ text: String) {
    statusLabel.text = text
  }

  private func refreshAvailabilityComposer(with draft: PlanningDraft) {
    availabilityWindowLabel.text = draft.board.windowSummary
    availabilitySummaryLabel.text = draft.board.selectionSummary
    availabilityButtons.removeAll()
    draggedSlotIds.removeAll()
    dragSelectionMode = nil

    for arrangedSubview in availabilityGridContainer.arrangedSubviews {
      availabilityGridContainer.removeArrangedSubview(arrangedSubview)
      arrangedSubview.removeFromSuperview()
    }

    let headerRow = UIStackView()
    headerRow.axis = .horizontal
    headerRow.spacing = 2
    availabilityGridContainer.addArrangedSubview(headerRow)

    let spacer = UILabel()
    spacer.text = "Time"
    spacer.font = .preferredFont(forTextStyle: .caption1)
    spacer.textColor = .secondaryLabel
    spacer.textAlignment = .left
    spacer.widthAnchor.constraint(equalToConstant: gridTimeColumnWidth).isActive = true
    headerRow.addArrangedSubview(spacer)

    for day in draft.board.days {
      let label = UILabel()
      label.font = .preferredFont(forTextStyle: .caption1)
      label.textColor = .secondaryLabel
      label.textAlignment = .center
      label.numberOfLines = 2
      label.text = day.shortHeader
      label.widthAnchor.constraint(equalToConstant: gridDayColumnWidth).isActive = true
      headerRow.addArrangedSubview(label)
    }

    for timeIndex in draft.board.timeIndexes {
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 2
      row.alignment = .fill

      let timeLabel = UILabel()
      timeLabel.font = .preferredFont(forTextStyle: .caption1)
      timeLabel.textColor = .secondaryLabel
      timeLabel.text = draft.board.displayTimeLabel(for: timeIndex)
      timeLabel.widthAnchor.constraint(equalToConstant: gridTimeColumnWidth).isActive = true
      row.addArrangedSubview(timeLabel)

      for slot in draft.board.slots(for: timeIndex) {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 6
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 0.5
        button.accessibilityIdentifier = slot.id
        button.accessibilityLabel = slot.accessibilityLabel
        button.addTarget(self, action: #selector(toggleAvailabilitySlot(_:)), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: gridDayColumnWidth).isActive = true
        button.heightAnchor.constraint(equalToConstant: gridCellHeight).isActive = true
        styleAvailabilityButton(button, isSelected: draft.board.selectedSlotIds.contains(slot.id))
        availabilityButtons[slot.id] = button
        row.addArrangedSubview(button)
      }

      availabilityGridContainer.addArrangedSubview(row)
    }
  }

  private func makeDraftFromFields() -> PlanningDraft {
    let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    let organizer = organizerField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

    return PlanningDraft(
      title: title?.isEmpty == false ? title! : "New plan",
      organizer: organizer?.isEmpty == false ? organizer! : "Organizer",
      participants: hasSelectedDraftMessage ? currentDraft.participants : [],
      board: currentDraft.board,
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
  private func expandComposer() {
    ensureExpandedPresentation(force: true)
  }

  @objc
  private func dismissKeyboard() {
    view.endEditing(true)
  }

  @objc
  private func toggleAvailabilitySlot(_ sender: UIButton) {
    guard let slotId = sender.accessibilityIdentifier else {
      return
    }

    let shouldSelect = !currentDraft.board.selectedSlotIds.contains(slotId)
    setAvailabilitySlot(slotId, isSelected: shouldSelect)
    refreshPreview(with: currentDraft)
    setStatus(currentDraft.board.selectionStatus)
  }

  @objc
  private func handleAvailabilityPan(_ gesture: UIPanGestureRecognizer) {
    let location = gesture.location(in: availabilityGridContainer)

    switch gesture.state {
    case .began:
      draggedSlotIds.removeAll()
      guard let button = availabilityButton(at: location),
            let slotId = button.accessibilityIdentifier else {
        dragSelectionMode = nil
        return
      }
      let shouldSelect = !currentDraft.board.selectedSlotIds.contains(slotId)
      dragSelectionMode = shouldSelect
      applyDraggedSelection(slotId: slotId, shouldSelect: shouldSelect)
    case .changed:
      guard let shouldSelect = dragSelectionMode,
            let button = availabilityButton(at: location),
            let slotId = button.accessibilityIdentifier else {
        return
      }
      applyDraggedSelection(slotId: slotId, shouldSelect: shouldSelect)
    case .ended, .cancelled, .failed:
      dragSelectionMode = nil
      draggedSlotIds.removeAll()
      refreshPreview(with: currentDraft)
      setStatus(currentDraft.board.selectionStatus)
    default:
      break
    }
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
    refreshAvailabilityComposer(with: draft)
    refreshPreview(with: draft)

    let message = MSMessage(session: conversation.selectedMessage?.session ?? MSSession())
    message.url = draft.url
    message.layout = draft.messageLayout()
    message.summaryText = "Planning draft: \(draft.title)"

    conversation.insert(message) { [weak self] error in
      guard let self else { return }
      if let error {
        self.setStatus("Could not insert the availability card: \(error.localizedDescription)")
        return
      }

      self.hasSelectedDraftMessage = true
      self.updateInsertButtonTitle()
      self.modeControl.selectedSegmentIndex = Mode.compose.rawValue
      self.updateVisibleSection()
      self.setStatus("Availability board shared. People can reopen it in Messages and keep using the grid.")
    }
  }

  @objc
  private func openPlanner() {
    dismissKeyboard()
    let draft = makeDraftFromFields()
    currentDraft = draft
    refreshAvailabilityComposer(with: draft)
    refreshPreview(with: draft)

    extensionContext?.open(draft.url) { [weak self] success in
      self?.setStatus(
        success
          ? "Opening the full availability board..."
          : "Could not open the full board. Make sure the app is installed."
      )
    }
  }

  private func ensureExpandedPresentation(force: Bool = false) {
    if presentationStyle == .expanded {
      hasRequestedExpansion = false
      updateVisibleSection()
      return
    }
    if hasRequestedExpansion && !force {
      updateVisibleSection()
      return
    }
    hasRequestedExpansion = true
    requestPresentationStyle(.expanded)
    updateVisibleSection()
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    switch textField {
    case titleField:
      organizerField.becomeFirstResponder()
    default:
      dismissKeyboard()
    }
    return true
  }

  private func applyDraggedSelection(slotId: String, shouldSelect: Bool) {
    guard !draggedSlotIds.contains(slotId) else {
      return
    }
    draggedSlotIds.insert(slotId)
    setAvailabilitySlot(slotId, isSelected: shouldSelect)
  }

  private func setAvailabilitySlot(_ slotId: String, isSelected: Bool) {
    let currentSelection = currentDraft.board.selectedSlotIds.contains(slotId)
    guard currentSelection != isSelected else {
      return
    }

    currentDraft = currentDraft.with(board: currentDraft.board.setting(slotId, isSelected: isSelected))
    if let button = availabilityButtons[slotId] {
      styleAvailabilityButton(button, isSelected: isSelected)
    }
    availabilitySummaryLabel.text = currentDraft.board.selectionSummary
  }

  private func availabilityButton(at location: CGPoint) -> UIButton? {
    availabilityButtons.values.first { button in
      let frame = button.convert(button.bounds, to: availabilityGridContainer).insetBy(dx: -2, dy: -2)
      return frame.contains(location)
    }
  }

  private func styleAvailabilityButton(_ button: UIButton, isSelected: Bool) {
    button.backgroundColor = isSelected ? UIColor.systemBlue : UIColor.systemGray6
    button.layer.borderColor = (isSelected ? UIColor.systemBlue : UIColor.systemGray4).cgColor
    button.setTitle(nil, for: .normal)
  }
}

private struct AvailabilitySlot {
  let id: String
  let date: Date
  let dayIndex: Int
  let timeIndex: Int

  var accessibilityLabel: String {
    "\(date.formattedDay), \(date.formattedTime)"
  }
}

private struct AvailabilityBoard {
  static let calendar = Calendar.current
  static let defaultStartDate = calendar.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
  static let isoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  let startDate: Date
  let dayCount: Int
  let startHour: Int
  let endHour: Int
  let intervalMinutes: Int
  let selectedSlotIds: Set<String>

  init(
    startDate: Date = AvailabilityBoard.defaultStartDate,
    dayCount: Int = 7,
    startHour: Int = 8,
    endHour: Int = 22,
    intervalMinutes: Int = 30,
    selectedSlotIds: Set<String> = []
  ) {
    self.startDate = AvailabilityBoard.calendar.startOfDay(for: startDate)
    self.dayCount = dayCount
    self.startHour = startHour
    self.endHour = endHour
    self.intervalMinutes = intervalMinutes
    self.selectedSlotIds = selectedSlotIds
  }

  var days: [Date] {
    (0..<dayCount).compactMap { offset in
      AvailabilityBoard.calendar.date(byAdding: .day, value: offset, to: startDate)
    }
  }

  var timeIndexes: [Int] {
    let totalMinutes = max((endHour - startHour) * 60, intervalMinutes)
    return Array(stride(from: 0, to: totalMinutes, by: intervalMinutes))
  }

  var windowSummary: String {
    let dateRange: String
    if let firstDay = days.first, let lastDay = days.last {
      dateRange = dayCount >= 7
        ? "Week of \(firstDay.formattedShortDay)"
        : "\(firstDay.formattedShortDay) to \(lastDay.formattedShortDay)"
    } else {
      dateRange = "Availability window"
    }
    return "\(dateRange) • \(timeLabel(for: timeIndexes.first ?? 0)) to \(timeLabel(for: (timeIndexes.last ?? 0) + intervalMinutes))"
  }

  var selectionSummary: String {
    if selectedSlotIds.isEmpty {
      return "No time blocks selected yet. Drag across the board directly in Messages."
    }
    return "\(selectedSlotIds.count) blocks selected in Messages. Reopen this shared card anytime to keep editing the board."
  }

  var selectionStatus: String {
    if selectedSlotIds.isEmpty {
      return "No time blocks selected yet. Drag through the week view in Messages to build the board."
    }
    return "\(selectedSlotIds.count) time blocks selected in Messages."
  }

  func displayTimeLabel(for minutesOffset: Int) -> String {
    let totalMinutes = startHour * 60 + minutesOffset
    let minute = totalMinutes % 60
    return minute == 0 ? timeLabel(for: minutesOffset) : " "
  }

  func timeLabel(for minutesOffset: Int) -> String {
    let totalMinutes = startHour * 60 + minutesOffset
    let hour = totalMinutes / 60
    let minute = totalMinutes % 60
    var components = DateComponents()
    components.year = 2026
    components.month = 1
    components.day = 1
    components.hour = hour
    components.minute = minute
    let date = AvailabilityBoard.calendar.date(from: components) ?? Date()
    return date.formattedTime
  }

  func slots(for timeIndex: Int) -> [AvailabilitySlot] {
    days.enumerated().compactMap { dayIndex, day in
      var components = AvailabilityBoard.calendar.dateComponents([.year, .month, .day], from: day)
      components.hour = startHour + (timeIndex / 60)
      components.minute = timeIndex % 60
      guard let slotDate = AvailabilityBoard.calendar.date(from: components) else {
        return nil
      }
      return AvailabilitySlot(
        id: slotID(dayIndex: dayIndex, timeIndex: timeIndex),
        date: slotDate,
        dayIndex: dayIndex,
        timeIndex: timeIndex
      )
    }
  }

  func toggled(_ slotId: String) -> AvailabilityBoard {
    var next = selectedSlotIds
    if next.contains(slotId) {
      next.remove(slotId)
    } else {
      next.insert(slotId)
    }

    return AvailabilityBoard(
      startDate: startDate,
      dayCount: dayCount,
      startHour: startHour,
      endHour: endHour,
      intervalMinutes: intervalMinutes,
      selectedSlotIds: next
    )
  }

  func setting(_ slotId: String, isSelected: Bool) -> AvailabilityBoard {
    var next = selectedSlotIds
    if isSelected {
      next.insert(slotId)
    } else {
      next.remove(slotId)
    }

    return AvailabilityBoard(
      startDate: startDate,
      dayCount: dayCount,
      startHour: startHour,
      endHour: endHour,
      intervalMinutes: intervalMinutes,
      selectedSlotIds: next
    )
  }

  func selectedSlotSummary(limit: Int = 4) -> String {
    let ordered = timeIndexes.flatMap { slots(for: $0) }
      .filter { selectedSlotIds.contains($0.id) }
      .prefix(limit)
      .map { "\($0.date.formattedDay), \($0.date.formattedTime)" }

    if ordered.isEmpty {
      return "Tap the board in Messages to choose the time blocks that work."
    }
    return ordered.joined(separator: " • ")
  }

  private func slotID(dayIndex: Int, timeIndex: Int) -> String {
    "\(dayIndex)-\(timeIndex)"
  }
}

private struct PlanningDraft {
  let title: String
  let organizer: String
  let participants: [String]
  let board: AvailabilityBoard
  let prompt: String

  init(
    title: String,
    organizer: String,
    participants: [String],
    board: AvailabilityBoard,
    prompt: String
  ) {
    self.title = title
    self.organizer = organizer
    self.participants = participants
    self.board = board
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
    let title = queryItems.first(where: { $0.name == "title" })?.value ?? "Availability board"
    let organizer = queryItems.first(where: { $0.name == "createdBy" })?.value ?? "Organizer"
    let prompt =
      queryItems.first(where: { $0.name == "prompt" })?.value ??
      "Collect availability first, then lock the best overlap in the full board."
    let startDateString = queryItems.first(where: { $0.name == "startDate" })?.value
    let startDate = startDateString.flatMap { AvailabilityBoard.isoFormatter.date(from: $0) } ?? AvailabilityBoard.defaultStartDate
    let dayCount = Int(queryItems.first(where: { $0.name == "dayCount" })?.value ?? "") ?? 7
    let startHour = Int(queryItems.first(where: { $0.name == "startHour" })?.value ?? "") ?? 8
    let endHour = Int(queryItems.first(where: { $0.name == "endHour" })?.value ?? "") ?? 22
    let intervalMinutes = Int(queryItems.first(where: { $0.name == "intervalMinutes" })?.value ?? "") ?? 30
    let selectedSlotIds = Set(
      (queryItems.first(where: { $0.name == "selectedSlots" })?.value ?? "")
        .split(separator: ",")
        .map { String($0) }
    )
    let participants = (queryItems.first(where: { $0.name == "participants" })?.value ?? "")
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    self.init(
      title: title,
      organizer: organizer,
      participants: participants,
      board: AvailabilityBoard(
        startDate: startDate,
        dayCount: dayCount,
        startHour: startHour,
        endHour: endHour,
        intervalMinutes: intervalMinutes,
        selectedSlotIds: selectedSlotIds
      ),
      prompt: prompt
    )
  }

  var url: URL {
    var components = URLComponents()
    components.scheme = "chatutilitieshub"
    components.host = "compose"
    var queryItems = [
      URLQueryItem(name: "title", value: title),
      URLQueryItem(name: "prompt", value: prompt),
      URLQueryItem(name: "createdBy", value: organizer),
      URLQueryItem(name: "startDate", value: AvailabilityBoard.isoFormatter.string(from: board.startDate)),
      URLQueryItem(name: "dayCount", value: "\(board.dayCount)"),
      URLQueryItem(name: "startHour", value: "\(board.startHour)"),
      URLQueryItem(name: "endHour", value: "\(board.endHour)"),
      URLQueryItem(name: "intervalMinutes", value: "\(board.intervalMinutes)"),
    ]
    if !board.selectedSlotIds.isEmpty {
      queryItems.append(
        URLQueryItem(name: "selectedSlots", value: board.selectedSlotIds.sorted().joined(separator: ","))
      )
    }
    if !participants.isEmpty {
      queryItems.append(
        URLQueryItem(name: "participants", value: participants.joined(separator: ","))
      )
    }
    components.queryItems = queryItems
    return components.url!
  }

  func messageLayout() -> MSMessageTemplateLayout {
    let layout = MSMessageTemplateLayout()
    layout.caption = title
    layout.subcaption = organizer
    layout.trailingCaption = board.selectedSlotIds.isEmpty ? "Pick times" : "\(board.selectedSlotIds.count) blocks"
    layout.trailingSubcaption = "Availability"
    layout.image = previewImage()
    return layout
  }

  func with(board: AvailabilityBoard) -> PlanningDraft {
    PlanningDraft(
      title: title,
      organizer: organizer,
      participants: participants,
      board: board,
      prompt: prompt
    )
  }

  var previewSummary: String {
    if participants.isEmpty {
      return board.selectedSlotSummary()
    }
    return "\(board.selectedSlotSummary())\nPeople on board: \(participants.joined(separator: ", "))"
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
      NSString(string: "Availability Board").draw(
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

      NSString(string: conversationSummary).draw(
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
      NSString(string: "Open this card in Messages to keep editing the scheduling grid.").draw(
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

  private var conversationSummary: String {
    let boardSummary = board.selectedSlotIds.isEmpty
      ? "Tap the in-Messages board to choose times."
      : "\(board.selectedSlotIds.count) blocks selected: \(board.selectedSlotSummary(limit: 2))"
    if participants.isEmpty {
      return boardSummary
    }
    let visibleNames = participants.prefix(4).joined(separator: ", ")
    if participants.count <= 4 {
      return "\(boardSummary)\nPeople already on the board: \(visibleNames)"
    }
    return "\(boardSummary)\nPeople already on the board: \(visibleNames) +\(participants.count - 4) more"
  }
}

private extension Date {
  static let shortHeaderFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("EEE\nM/d")
    return formatter
  }()

  static let shortDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("EEE M/d")
    return formatter
  }()

  static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
    return formatter
  }()

  static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("h:mm a")
    return formatter
  }()

  var shortHeader: String {
    Date.shortHeaderFormatter.string(from: self)
  }

  var formattedShortDay: String {
    Date.shortDayFormatter.string(from: self)
  }

  var formattedDay: String {
    Date.dayFormatter.string(from: self)
  }

  var formattedTime: String {
    Date.timeFormatter.string(from: self)
  }
}
