//
//  InferenceViewController.swift
//  LivenessSDK
//
//  Created by Anh Loc Mascom on 12/09/2023.
//


import UIKit
import MediaPipeTasksVision

protocol InferenceViewControllerDelegate {

  /**
   This method is called when the user changes the value to update model used for inference.
   **/
  func viewController(
    _ viewController: InferenceViewController,
    needPerformActions action: InferenceViewController.Action)
}

class InferenceViewController: UIViewController {

  enum Action {
    case changeNumFaces(Int)
    case changeDetectionConfidence(Float)
    case changePresenceConfidence(Float)
    case changeTrackingConfidence(Float)
    case changeBottomSheetViewBottomSpace(Bool)
    case changeVerticalThresholdMove(Float)

  }

  // MARK: Delegate
  var delegate: InferenceViewControllerDelegate?

  // MARK: Storyboards Connections
  @IBOutlet weak var infrenceTimeLabel: UILabel!
  @IBOutlet weak var infrenceTimeTitleLabel: UILabel!
  @IBOutlet weak var detectionConfidenceStepper: UIStepper!
  @IBOutlet weak var detectionConfidenceValueLabel: UILabel!

  @IBOutlet weak var presenceConfidenceStepper: UIStepper!
  @IBOutlet weak var presenceConfidenceValueLabel: UILabel!

  @IBOutlet weak var minTrackingConfidenceStepper: UIStepper!
  @IBOutlet weak var minTrackingConfidenceValueLabel: UILabel!

  @IBOutlet weak var numFacesStepper: UIStepper!
  @IBOutlet weak var numFacestLabel: UILabel!
    @IBOutlet weak var detectionVerThreshold: UIStepper!
    @IBOutlet weak var verticalThresholdValueLabel: UILabel!

  // MARK: Instance Variables
  var result: ResultBundle? = nil
  var numFaces = DefaultConstants.numFaces
  var minFaceDetectionConfidence = DefaultConstants.detectionConfidence
  var minFacePresenceConfidence = DefaultConstants.presenceConfidence
  var minTrackingConfidence = DefaultConstants.trackingConfidence
    var minTrackingThresholdVertical = DefaultConstants.trackingConfidenceThresholdVertical

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  // Private function
  private func setupUI() {

    detectionConfidenceStepper.value = Double(minFaceDetectionConfidence)
    detectionConfidenceValueLabel.text = "\(minFaceDetectionConfidence)"

    presenceConfidenceStepper.value = Double(minFacePresenceConfidence)
    presenceConfidenceValueLabel.text = "\(minFacePresenceConfidence)"

    minTrackingConfidenceStepper.value = Double(minTrackingConfidence)
    minTrackingConfidenceValueLabel.text = "\(minTrackingConfidence)"
      verticalThresholdValueLabel.text = "\(minTrackingThresholdVertical)"

    numFacesStepper.value = Double(numFaces)
    numFacestLabel.text = "\(numFaces)"
  }

  // Public function
  func updateData() {
    if let inferenceTime = result?.inferenceTime {
      infrenceTimeLabel.text = String(format: "%.2fms", inferenceTime)
    }
  }
  // MARK: IBAction

  @IBAction func expandButtonTouchUpInside(_ sender: UIButton) {
    sender.isSelected.toggle()
    infrenceTimeLabel.isHidden = !sender.isSelected
    infrenceTimeTitleLabel.isHidden = !sender.isSelected
    delegate?.viewController(self, needPerformActions: .changeBottomSheetViewBottomSpace(sender.isSelected))
  }

  @IBAction func detectionConfidenceStepperValueChanged(_ sender: UIStepper) {
    minFaceDetectionConfidence = Float(sender.value)
    delegate?.viewController(self, needPerformActions: .changeDetectionConfidence(minFaceDetectionConfidence))
    detectionConfidenceValueLabel.text = "\(minFaceDetectionConfidence)"
  }

  @IBAction func presenceConfidenceStepperValueChanged(_ sender: UIStepper) {
    minFacePresenceConfidence = Float(sender.value)
    delegate?.viewController(self, needPerformActions: .changePresenceConfidence(minFacePresenceConfidence))
    presenceConfidenceValueLabel.text = "\(minFacePresenceConfidence)"
  }

  @IBAction func minTrackingConfidenceStepperValueChanged(_ sender: UIStepper) {
    minTrackingConfidence = Float(sender.value)
    delegate?.viewController(self, needPerformActions: .changeTrackingConfidence(minTrackingConfidence))
    minTrackingConfidenceValueLabel.text = "\(minTrackingConfidence)"
  }

    @IBAction func verticalThresholdValueChange(_ sender: UIStepper) {
        minTrackingThresholdVertical = Float(sender.value)
        delegate?.viewController(self, needPerformActions: .changeVerticalThresholdMove(minTrackingThresholdVertical))
        verticalThresholdValueLabel.text = "\(minTrackingThresholdVertical)"
        
    }
    @IBAction func numFacesStepperValueChanged(_ sender: UIStepper) {
    numFaces = Int(sender.value)
    delegate?.viewController(self, needPerformActions: .changeNumFaces(numFaces))
    numFacestLabel.text = "\(numFaces)"
  }
}
