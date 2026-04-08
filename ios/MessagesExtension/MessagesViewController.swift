import Messages
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
  private let titleField = UITextField()
  private let organizerField = UITextField()
  private let participantsField = UITextField()
  private let statusLabel = UILabel()
  private let insertButton = UIButton(type: .system)
  private let openButton = UIButton(type: .system)
  private var currentDraft = PlanningDraft(
    title: "Dinner plan",
    organizer: "Maya",
    participants: ["Maya", "Jordan", "Ari"],
    prompt: "Find the best overlap, then finish the plan in the full board."
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
    syncFields(with: currentDraft)
  }

  override func willBecomeActive(with conversation: MSConversation) {
    super.willBecomeActive(with: conversation)
    if let message = conversation.selectedMessage,
       let draft = PlanningDraft(url: message.url) {
      currentDraft = draft
      syncFields(with: draft)
      statusLabel.text = "This card is ready. Open the full Flutter planner to finish the board."
      return
    }

    statusLabel.text = "Create a draft in chat, then hand the full board to Flutter."
  }

  override func didSelect(_ message: MSMessage, conversation: MSConversation) {
    super.didSelect(message, conversation: conversation)
    guard let draft = PlanningDraft(url: message.url) else {
      return
    }
    currentDraft = draft
    syncFields(with: draft)
    statusLabel.text = "Loaded the draft from this message. You can resend it or open the full planner."
  }

  private func configureView() {
    view.backgroundColor = .systemGroupedBackground

    let titleLabel = sectionLabel("Plan title")
    let organizerLabel = sectionLabel("Organizer")
    let participantsLabel = sectionLabel("Participants")

    titleField.placeholder = "Game night"
    organizerField.placeholder = "Who is kicking this off?"
    participantsField.placeholder = "Maya, Jordan, Ari"

    [titleField, organizerField, participantsField].forEach { field in
      field.borderStyle = .roundedRect
      field.backgroundColor = .secondarySystemBackground
      field.autocapitalizationType = .words
    }
    participantsField.autocapitalizationType = .sentences

    statusLabel.font = .preferredFont(forTextStyle: .subheadline)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0

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

    let stack = UIStackView(
      arrangedSubviews: [
        headerView(),
        titleLabel,
        titleField,
        organizerLabel,
        organizerField,
        participantsLabel,
        participantsField,
        statusLabel,
        buttonRow,
      ]
    )
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      titleField.heightAnchor.constraint(equalToConstant: 44),
      organizerField.heightAnchor.constraint(equalToConstant: 44),
      participantsField.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  private func headerView() -> UIView {
    let eyebrow = UILabel()
    eyebrow.font = .preferredFont(forTextStyle: .caption1)
    eyebrow.textColor = .systemBlue
    eyebrow.text = "iMessage Draft"

    let title = UILabel()
    title.font = .preferredFont(forTextStyle: .title2)
    title.textColor = .label
    title.numberOfLines = 0
    title.text = "Start the plan in Messages, then finish the board in Flutter."

    let detail = UILabel()
    detail.font = .preferredFont(forTextStyle: .body)
    detail.textColor = .secondaryLabel
    detail.numberOfLines = 0
    detail.text = "This extension stays intentionally lightweight. It captures the draft and hands the real scheduling flow to the main app."

    let stack = UIStackView(arrangedSubviews: [eyebrow, title, detail])
    stack.axis = .vertical
    stack.spacing = 6
    return stack
  }

  private func sectionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.text = text
    return label
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

  private func syncFields(with draft: PlanningDraft) {
    titleField.text = draft.title
    organizerField.text = draft.organizer
    participantsField.text = draft.participants.joined(separator: ", ")
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
  private func insertPlanningCard() {
    guard let conversation = activeConversation else {
      statusLabel.text = "Messages is not ready yet. Try again in a second."
      return
    }

    currentDraft = makeDraftFromFields()
    let message = MSMessage(session: conversation.selectedMessage?.session ?? MSSession())
    message.url = currentDraft.url
    let layout = MSMessageTemplateLayout()
    layout.caption = currentDraft.title
    layout.subcaption = "\(currentDraft.participants.count) people"
    layout.trailingCaption = "Plan"
    layout.trailingSubcaption = "Open in app"
    message.layout = layout
    message.summaryText = "Planning draft: \(currentDraft.title)"

    conversation.insert(message) { [weak self] error in
      if let error {
        self?.statusLabel.text = "Could not insert the planning card: \(error.localizedDescription)"
        return
      }

      self?.statusLabel.text = "Planning card inserted. Anyone in the chat can open the full board next."
      self?.requestPresentationStyle(.compact)
    }
  }

  @objc
  private func openPlanner() {
    currentDraft = makeDraftFromFields()
    extensionContext?.open(currentDraft.url) { [weak self] success in
      self?.statusLabel.text = success
        ? "Opening Chat Utilities Hub..."
        : "Could not open the full planner. Make sure the app is installed."
    }
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
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
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
    components.queryItems = queryItems
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
}
