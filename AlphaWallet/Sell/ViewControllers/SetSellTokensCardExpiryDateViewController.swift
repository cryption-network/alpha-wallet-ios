// Copyright © 2018 Stormbird PTE. LTD.

import UIKit

protocol SetSellTokensCardExpiryDateViewControllerDelegate: class, CanOpenURL {
    func didSetSellTokensExpiryDate(tokenHolder: TokenHolder, linkExpiryDate: Date, ethCost: Ether, in viewController: SetSellTokensCardExpiryDateViewController)
    func didPressViewInfo(in viewController: SetSellTokensCardExpiryDateViewController)
}

class SetSellTokensCardExpiryDateViewController: UIViewController, TokenVerifiableStatusViewController {

    let config: Config
    var contract: String {
        return viewModel.token.contract
    }
    let storage: TokensDataStore
    let roundedBackground = RoundedBackground()
    let scrollView = UIScrollView()
    let header = TokensCardViewControllerTitleHeader()
    let linkExpiryDateLabel = UILabel()
    let linkExpiryDateField = DateEntryField()
    let linkExpiryTimeLabel = UILabel()
    let linkExpiryTimeField = TimeEntryField()
    let tokenCountLabel = UILabel()
    let perTokenPriceLabel = UILabel()
    let totalEthLabel = UILabel()
    let descriptionLabel = UILabel()
    let noteTitleLabel = UILabel()
    let noteLabel = UILabel()
    let noteBorderView = UIView()
    let tokenRowView: TokenRowView & UIView
    let nextButton = UIButton(type: .system)
    let datePicker = UIDatePicker()
    let timePicker = UIDatePicker()
    var viewModel: SetSellTokensCardExpiryDateViewControllerViewModel
    let paymentFlow: PaymentFlow
    let tokenHolder: TokenHolder
    let ethCost: Ether
    weak var delegate: SetSellTokensCardExpiryDateViewControllerDelegate?

    init(
            config: Config,
            storage: TokensDataStore,
            paymentFlow: PaymentFlow,
            tokenHolder: TokenHolder,
            ethCost: Ether,
            viewModel: SetSellTokensCardExpiryDateViewControllerViewModel
    ) {
        self.config = config
        self.storage = storage
        self.paymentFlow = paymentFlow
        self.tokenHolder = tokenHolder
        self.ethCost = ethCost
        self.viewModel = viewModel

        let tokenType = CryptoKittyHandling(contract: tokenHolder.contractAddress)
        switch tokenType {
        case .cryptoKitty:
            tokenRowView = TokenListFormatRowView()
        case .otherNonFungibleToken:
            tokenRowView = TokenCardRowView()
        }

        super.init(nibName: nil, bundle: nil)

        updateNavigationRightBarButtons(isVerified: true)

        roundedBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roundedBackground)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        roundedBackground.addSubview(scrollView)

        nextButton.setTitle(R.string.localizable.aWalletNextButtonTitle(), for: .normal)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)

        tokenRowView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tokenRowView)

        linkExpiryDateLabel.translatesAutoresizingMaskIntoConstraints = false
        linkExpiryTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        tokenCountLabel.translatesAutoresizingMaskIntoConstraints = false
        perTokenPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        totalEthLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        noteTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        noteLabel.translatesAutoresizingMaskIntoConstraints = false

        noteBorderView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(noteBorderView)

        linkExpiryDateField.translatesAutoresizingMaskIntoConstraints = false
        linkExpiryDateField.value = Date.tomorrow
        linkExpiryDateField.delegate = self

        linkExpiryTimeField.translatesAutoresizingMaskIntoConstraints = false
        linkExpiryTimeField.delegate = self

        let col0 = [
            linkExpiryDateLabel,
            .spacer(height: 4),
            linkExpiryDateField,
        ].asStackView(axis: .vertical)
        col0.translatesAutoresizingMaskIntoConstraints = false

        let col1 = [
            linkExpiryTimeLabel,
            .spacer(height: 4),
            linkExpiryTimeField,
        ].asStackView(axis: .vertical)
        col1.translatesAutoresizingMaskIntoConstraints = false

        let choicesStackView = [col0, .spacerWidth(10), col1].asStackView()
        choicesStackView.translatesAutoresizingMaskIntoConstraints = false

        let noteStackView = [
            noteTitleLabel,
            .spacer(height: 4),
            noteLabel,
        ].asStackView(axis: .vertical)
        noteStackView.translatesAutoresizingMaskIntoConstraints = false
        noteBorderView.addSubview(noteStackView)

        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        datePicker.isHidden = true
        if let locale = config.locale {
            datePicker.locale = Locale(identifier: locale)
        }

        timePicker.datePickerMode = .time
        timePicker.minimumDate = Date.yesterday
        timePicker.addTarget(self, action: #selector(timePickerValueChanged), for: .valueChanged)
        timePicker.isHidden = true
        if let locale = config.locale {
            timePicker.locale = Locale(identifier: locale)
        }

        let stackView = [
            header,
            tokenRowView,
            .spacer(height: 18),
            tokenCountLabel,
            perTokenPriceLabel,
            totalEthLabel,
            .spacer(height: 4),
            descriptionLabel,
            .spacer(height: 18),
            choicesStackView,
            datePicker,
            timePicker,
            .spacer(height: 10),
            noteBorderView,
        ].asStackView(axis: .vertical, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        let buttonsStackView = [nextButton].asStackView(distribution: .fillEqually, contentHuggingPriority: .required)
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false

        let footerBar = UIView()
        footerBar.translatesAutoresizingMaskIntoConstraints = false
        footerBar.backgroundColor = Colors.appHighlightGreen
        roundedBackground.addSubview(footerBar)

        let buttonsHeight = CGFloat(60)
        footerBar.addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
			header.heightAnchor.constraint(equalToConstant: 90),
            //Strange repositioning of header horizontally while typing without this
            header.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            tokenRowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tokenRowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            linkExpiryDateField.leadingAnchor.constraint(equalTo: tokenRowView.background.leadingAnchor),
            linkExpiryTimeField.rightAnchor.constraint(equalTo: tokenRowView.background.rightAnchor),
            linkExpiryDateField.heightAnchor.constraint(equalToConstant: 50),
            linkExpiryDateField.widthAnchor.constraint(equalTo: linkExpiryTimeField.widthAnchor),
            linkExpiryDateField.heightAnchor.constraint(equalTo: linkExpiryTimeField.heightAnchor),

            datePicker.leadingAnchor.constraint(equalTo: tokenRowView.background.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: tokenRowView.background.trailingAnchor),

            timePicker.leadingAnchor.constraint(equalTo: tokenRowView.background.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: tokenRowView.background.trailingAnchor),

            noteBorderView.leadingAnchor.constraint(equalTo: tokenRowView.background.leadingAnchor),
            noteBorderView.trailingAnchor.constraint(equalTo: tokenRowView.background.trailingAnchor),

            noteStackView.leadingAnchor.constraint(equalTo: noteBorderView.leadingAnchor, constant: 10),
            noteStackView.trailingAnchor.constraint(equalTo: noteBorderView.trailingAnchor, constant: -10),
            noteStackView.topAnchor.constraint(equalTo: noteBorderView.topAnchor, constant: 10),
            noteStackView.bottomAnchor.constraint(equalTo: noteBorderView.bottomAnchor, constant: -10),

            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            buttonsStackView.leadingAnchor.constraint(equalTo: footerBar.leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: footerBar.trailingAnchor),
            buttonsStackView.topAnchor.constraint(equalTo: footerBar.topAnchor),
            buttonsStackView.heightAnchor.constraint(equalToConstant: buttonsHeight),

            footerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerBar.heightAnchor.constraint(equalToConstant: buttonsHeight),
            footerBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerBar.topAnchor),
        ] + roundedBackground.createConstraintsWithContainer(view: view))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func nextButtonTapped() {
        let expiryDate = linkExpiryDate()
        guard expiryDate > Date() else {
            UIAlertController.alert(title: "",
                    message: R.string.localizable.aWalletTokenSellLinkExpiryTimeAtLeastNowTitle(),
                    alertButtonTitles: [R.string.localizable.oK()],
                    alertButtonStyles: [.cancel],
                    viewController: self,
                    completion: nil)
            return
        }

        //TODO be good if we check if date chosen is not too far into the future. Example 1 year ahead. Common error?
        delegate?.didSetSellTokensExpiryDate(tokenHolder: tokenHolder, linkExpiryDate: linkExpiryDate(), ethCost: ethCost, in: self)
    }

    private func linkExpiryDate() -> Date {
        let hour = NSCalendar.current.component(.hour, from: linkExpiryTimeField.value)
        let minutes = NSCalendar.current.component(.minute, from: linkExpiryTimeField.value)
        let seconds = NSCalendar.current.component(.second, from: linkExpiryTimeField.value)
        if let date = NSCalendar.current.date(bySettingHour: hour, minute: minutes, second: seconds, of: linkExpiryDateField.value) {
            return date
        } else {
            return Date()
        }
    }

    func showInfo() {
        delegate?.didPressViewInfo(in: self)
    }

    func showContractWebPage() {
        delegate?.didPressViewContractWebPage(forContract: contract, in: self)
    }

    func configure(viewModel newViewModel: SetSellTokensCardExpiryDateViewControllerViewModel? = nil) {
        if let newViewModel = newViewModel {
            viewModel = newViewModel
        }
        updateNavigationRightBarButtons(isVerified: isContractVerified)

        view.backgroundColor = viewModel.backgroundColor

        header.configure(title: viewModel.headerTitle)

        tokenRowView.configure(tokenHolder: viewModel.tokenHolder)

        linkExpiryDateLabel.textAlignment = .center
        linkExpiryDateLabel.textColor = viewModel.choiceLabelColor
        linkExpiryDateLabel.font = viewModel.choiceLabelFont
        linkExpiryDateLabel.text = viewModel.linkExpiryDateLabelText

        linkExpiryTimeLabel.textAlignment = .center
        linkExpiryTimeLabel.textColor = viewModel.choiceLabelColor
        linkExpiryTimeLabel.font = viewModel.choiceLabelFont
        linkExpiryTimeLabel.text = viewModel.linkExpiryTimeLabelText

        tokenCountLabel.textAlignment = .center
        tokenCountLabel.textColor = viewModel.tokenSaleDetailsLabelColor
        tokenCountLabel.font = viewModel.tokenSaleDetailsLabelFont
        tokenCountLabel.text = viewModel.tokenCountLabelText

        perTokenPriceLabel.textAlignment = .center
        perTokenPriceLabel.textColor = viewModel.tokenSaleDetailsLabelColor
        perTokenPriceLabel.font = viewModel.tokenSaleDetailsLabelFont
        perTokenPriceLabel.text = viewModel.perTokenPriceLabelText

        totalEthLabel.textAlignment = .center
        totalEthLabel.textColor = viewModel.tokenSaleDetailsLabelColor
        totalEthLabel.font = viewModel.tokenSaleDetailsLabelFont
        totalEthLabel.text = viewModel.totalEthLabelText

        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = viewModel.descriptionLabelColor
        descriptionLabel.font = viewModel.descriptionLabelFont
        descriptionLabel.text = viewModel.descriptionLabelText

        noteTitleLabel.textAlignment = .center
        noteTitleLabel.textColor = viewModel.noteTitleLabelColor
        noteTitleLabel.font = viewModel.noteTitleLabelFont
        noteTitleLabel.text = viewModel.noteTitleLabelText

        noteLabel.textAlignment = .center
        noteLabel.numberOfLines = 0
        noteLabel.textColor = viewModel.noteLabelColor
        noteLabel.font = viewModel.noteLabelFont
        noteLabel.text = viewModel.noteLabelText

        noteBorderView.layer.cornerRadius = 20
        noteBorderView.layer.borderColor = viewModel.noteBorderColor.cgColor
        noteBorderView.layer.borderWidth = 1

        tokenRowView.stateLabel.isHidden = true

        nextButton.setTitleColor(viewModel.buttonTitleColor, for: .normal)
		nextButton.backgroundColor = viewModel.buttonBackgroundColor
        nextButton.titleLabel?.font = viewModel.buttonFont
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        linkExpiryDateField.layer.cornerRadius = linkExpiryDateField.frame.size.height / 2
        linkExpiryTimeField.layer.cornerRadius = linkExpiryTimeField.frame.size.height / 2
    }

    @objc func datePickerValueChanged() {
        linkExpiryDateField.value = datePicker.date
    }

    @objc func timePickerValueChanged() {
        linkExpiryTimeField.value = timePicker.date
    }
}

extension SetSellTokensCardExpiryDateViewController: DateEntryFieldDelegate {
    func didTap(in dateEntryField: DateEntryField) {
        datePicker.isHidden = !datePicker.isHidden
        if !datePicker.isHidden {
            datePicker.date = linkExpiryDateField.value
            timePicker.isHidden = true
        }
    }
}

extension SetSellTokensCardExpiryDateViewController: TimeEntryFieldDelegate {
    func didTap(in timeEntryField: TimeEntryField) {
        timePicker.isHidden = !timePicker.isHidden
        if !timePicker.isHidden {
            timePicker.date = linkExpiryTimeField.value
            datePicker.isHidden = true
        }
    }
}