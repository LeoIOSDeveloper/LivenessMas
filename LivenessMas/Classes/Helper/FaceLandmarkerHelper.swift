// Copyright 2023 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import MediaPipeTasksVision
import AVFoundation
enum LivenessStep: String {
    case normal = "Move face to Camera"
    case moveLeft = "Move face to Left"
    case moveRight = "Move face to Right"
    case up = "Move face to Up"
    case down = "Move face to Down"
    case blink = "Blink your eye"
}
enum LivenessStepStatus: String {
    case success = "sucess"
    case failed = "faile"
}
struct LivenessStepModel {
    var currentStepStatus: LivenessStepStatus
    var currentStep: LivenessStep
    
    // You can add any additional properties or methods related to liveness here
    
    // Initialize the model with default values
    init() {
        currentStepStatus = .failed
        currentStep = .normal
    }
    
    // Method to advance to the next step
    mutating func moveToNextStep() {
        // Implement logic here to move to the next step
        // For example, you can increment the step or reset it if needed
        switch currentStep {
        case .normal:
            currentStep = .moveLeft
        case .moveLeft:
            currentStep = .moveRight
        case .moveRight:
            currentStep = .down
        case .down:
            currentStep = .up
        case .up:
            currentStep = .blink
        case .blink:
            currentStep = .blink

        }
        
        
        // Reset the step status when moving to the next step
        currentStepStatus = .failed
    }
}
protocol FaceLandmarkerHelperDelegate: AnyObject {
  func faceLandmarkerHelper(_ faceLandmarkerHelper: FaceLandmarkerHelper,
                            didFinishDetection result: ResultBundle?,
                            error: Error?)
    func facePoseHeadStepPass(livenessStep: LivenessStep, stepStatus: LivenessStepStatus)
}

class FaceLandmarkerHelper: NSObject {

  weak var delegate: FaceLandmarkerHelperDelegate?
  var faceLandmarker: FaceLandmarker?
    let eyeClosedThreshold: CGFloat = 0.2
    var countEyeClose = 0;
    
    public var trackingConfidenceThresholdVertical = DefaultConstants.trackingConfidenceThresholdVertical

  init(modelPath: String?, numFaces: Int, minFaceDetectionConfidence: Float, minFacePresenceConfidence: Float, minTrackingConfidence: Float, minTrackingVerticalThreshold: Float, runningModel: RunningMode, delegate: FaceLandmarkerHelperDelegate?) {
    super.init()
    guard let modelPath = modelPath else { return }
    let faceLandmarkerOptions = FaceLandmarkerOptions()
    faceLandmarkerOptions.runningMode = runningModel
    faceLandmarkerOptions.numFaces = numFaces
    faceLandmarkerOptions.minFaceDetectionConfidence = minFaceDetectionConfidence
    faceLandmarkerOptions.minFacePresenceConfidence = minFacePresenceConfidence
    faceLandmarkerOptions.minTrackingConfidence = minTrackingConfidence
    faceLandmarkerOptions.faceLandmarkerLiveStreamDelegate = runningModel == .liveStream ? self : nil
    self.delegate = delegate
    faceLandmarkerOptions.baseOptions.modelAssetPath = modelPath
    do {
      faceLandmarker = try FaceLandmarker(options: faceLandmarkerOptions)
    } catch {
      print(error)
    }
  }

  /**
   This method returns a FaceLandmarkerResult object and infrenceTime after receiving an image
   **/
  func detect(image: UIImage) -> ResultBundle? {
    guard let mpImage = try? MPImage(uiImage: image) else { return nil }
    do {
      let startDate = Date()
      let result = try faceLandmarker?.detect(image: mpImage)
      let inferenceTime = Date().timeIntervalSince(startDate) * 1000
      return ResultBundle(inferenceTime: inferenceTime, faceLandmarkerResults: [result])
    } catch {
      print(error)
      return nil
    }
  }

  /**
   This method return FaceLandmarkerResult and infrenceTime when receive videoFrame
   **/
  func detectAsync(videoFrame: CMSampleBuffer, orientation: UIImage.Orientation, timeStamps: Int) {
    guard let faceLandmarker = faceLandmarker,
          let image = try? MPImage(sampleBuffer: videoFrame, orientation: orientation) else { return }
    do {
      try faceLandmarker.detectAsync(image: image, timestampInMilliseconds: timeStamps)
    } catch {
      print(error)
    }
  }

  /**
   This method returns a FaceLandmarkerResults object and infrenceTime when receiving videoUrl and inferenceIntervalMs
   **/
  func detectVideoFile(url: URL, inferenceIntervalMs: Double) async -> ResultBundle? {
    guard let faceLandmarker = faceLandmarker else { return nil }
    let asset: AVAsset = AVAsset(url: url)
    guard let videoDurationMs = try? await asset.load(.duration).seconds * 1000 else { return nil }

    // Using AVAssetImageGenerator to produce images from video content
    let generator = AVAssetImageGenerator(asset:asset)
    generator.requestedTimeToleranceBefore = CMTimeMake(value: 1, timescale: 25)
    generator.requestedTimeToleranceAfter = CMTimeMake(value: 1, timescale: 25)
    generator.appliesPreferredTrackTransform = true
    let frameCount = Int(videoDurationMs / inferenceIntervalMs)
    var faceLandmarkerResults: [FaceLandmarkerResult?] = []
    var size: CGSize = .zero
    let startDate = Date()
    // Go through each frame and detect it
    for i in 0 ..< frameCount {
      let timestampMs = inferenceIntervalMs * Double(i) // ms
      let time = CMTime(seconds: timestampMs / 1000, preferredTimescale: 600)
      if let image = getImageFromVideo(generator, atTime: time) {
        size = image.size
        do {
          let result = try faceLandmarker.detect(videoFrame: MPImage(uiImage: image), timestampInMilliseconds: Int(timestampMs))
          faceLandmarkerResults.append(result)
        } catch {
          print(error)
          faceLandmarkerResults.append(nil)
        }
      } else {
        faceLandmarkerResults.append(nil)
      }
    }
    let inferenceTime = Date().timeIntervalSince(startDate) / Double(frameCount) * 1000
    return ResultBundle(inferenceTime: inferenceTime, faceLandmarkerResults: faceLandmarkerResults, imageSize: size)
  }

  /**
   This method returns an image object and  when receiving assetImageGenerator and time
   **/
  private func getImageFromVideo(_ generator: AVAssetImageGenerator, atTime time: CMTime) -> UIImage? {
    let image:CGImage?
    do {
      try image = generator.copyCGImage(at: time, actualTime:nil)
    } catch {
      print(error)
      return nil
    }
    guard let image = image else { return nil }
    return UIImage(cgImage: image)
  }
    
    
    /// Livenes step function
    func calcDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        return sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2))
    }
    
    func detectDirection(_ landmarks: [[NormalizedLandmark]], orientation: UIImage.Orientation, currentStep: LivenessStep) {
        guard !landmarks.isEmpty else {
            return
        }
        
        for landmark in landmarks {
            var transformedLandmark: [CGPoint]!
            
            switch orientation {
            case .left:
                transformedLandmark = landmark.map({CGPoint(x: CGFloat($0.y), y: 1 - CGFloat($0.x))})
            case .right:
                transformedLandmark = landmark.map({CGPoint(x: 1 - CGFloat($0.y), y: CGFloat($0.x))})
            default:
                transformedLandmark = landmark.map({CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))})
            }
            
            //Detect direction move left or right
            let leftDistance = calcDistance(point1: transformedLandmark[5], point2: transformedLandmark[234])
            let rightDistance = calcDistance(point1: transformedLandmark[5], point2: transformedLandmark[454])

            let threshold: CGFloat = 2.5
            var result = "Straight"
            delegate?.facePoseHeadStepPass(livenessStep: .normal, stepStatus: .success)

            if leftDistance < rightDistance {
                let ratio = rightDistance / leftDistance
                if ratio > threshold {
                    result = "Left"
                    delegate?.facePoseHeadStepPass(livenessStep: .moveLeft, stepStatus: .success)
                    return
                }
            } else if rightDistance < leftDistance {
                let ratio = leftDistance / rightDistance
                if ratio > threshold {
                    result = "Right"
                    delegate?.facePoseHeadStepPass(livenessStep: .moveRight, stepStatus: .success)
                    return
                }
            }
            print(result)
            
            //Detect direction Up or dow
            let upDistance = calcDistance(point1: transformedLandmark[5], point2: transformedLandmark[10])
            let downDistance = calcDistance(point1: transformedLandmark[5], point2: transformedLandmark[152])

            let thresholdVertical = self.trackingConfidenceThresholdVertical
            //                var result = "Straight"
            print(upDistance)
            print(downDistance)
            if upDistance < downDistance {
                print("upDistance < downDistance")
                let ratio = downDistance / upDistance
                print(ratio)

                if Float(ratio) > thresholdVertical {
                    result = "Up"
                    delegate?.facePoseHeadStepPass(livenessStep: .up, stepStatus: .success)
                    return
                }
            } else if downDistance < upDistance {
                print("downDistance < upDistance")
                let ratio =  upDistance / downDistance
                print(ratio)
                if Float(ratio) > thresholdVertical {
                    result = "Down"
                    delegate?.facePoseHeadStepPass(livenessStep: .down, stepStatus: .success)
                    return
                }
            }
            print(result)
            if(currentStep == LivenessStep.blink){
                detectEyesAction(transformedLandmark: transformedLandmark)
            }
        }
        
        
        
    }
    func detectEyesAction(transformedLandmark: [CGPoint]){
        // Replace these with the correct landmark indices for the inner and outer corners of the eyes
        let leftEyeInnerIndex = 145
        let leftEyeOuterIndex = 159
        let rightEyeInnerIndex = 374
        let rightEyeOuterIndex = 386
        
        // Calculate the aspect ratio for the left eye
        let leftEyeAspectRatio = calculateEyeAspectRatio(
            innerCorner: transformedLandmark[leftEyeInnerIndex],
            outerCorner: transformedLandmark[leftEyeOuterIndex]
        )
        
        // Calculate the aspect ratio for the right eye
        let rightEyeAspectRatio = calculateEyeAspectRatio(
            innerCorner: transformedLandmark[rightEyeInnerIndex],
            outerCorner: transformedLandmark[rightEyeOuterIndex]
        )
        
        // Detect the state of both eyes
        let leftEyeState = detectEyeState(aspectRatio: leftEyeAspectRatio)
//        let rightEyeState = detectEyeState(aspectRatio: rightEyeAspectRatio)

        print("Left Eye: \(leftEyeState)")
        if(countEyeClose == 5){
            print("Left Eye Count: 5")

            delegate?.facePoseHeadStepPass(livenessStep: .blink, stepStatus: .success)

        }
        
        
    }
    // Function to calculate eye aspect ratio
    func calculateEyeAspectRatio(innerCorner: CGPoint, outerCorner: CGPoint) -> CGFloat {
        let verticalDistance = abs(innerCorner.y - outerCorner.y)
        let horizontalDistance = abs(innerCorner.x - outerCorner.x)
        return horizontalDistance / verticalDistance
    }
    func detectEyeState(aspectRatio: CGFloat) -> String {
        print(aspectRatio)
        if( aspectRatio < eyeClosedThreshold ){
            return "Open"
        }else{
            countEyeClose += 1
            return  "Close"

        }
    }
}

extension FaceLandmarkerHelper: FaceLandmarkerLiveStreamDelegate {
  func faceLandmarker(_ faceLandmarker: FaceLandmarker, didFinishDetection result: FaceLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
    guard let result = result else {
      delegate?.faceLandmarkerHelper(self, didFinishDetection: nil, error: error)
      return
    }
    let resultBundle = ResultBundle(
      inferenceTime: Date().timeIntervalSince1970 * 1000 - Double(timestampInMilliseconds),
      faceLandmarkerResults: [result])
    delegate?.faceLandmarkerHelper(self, didFinishDetection: resultBundle, error: nil)
  }


}

/// A result from the `FaceLandmarkerHelper`.
struct ResultBundle {
  let inferenceTime: Double
  let faceLandmarkerResults: [FaceLandmarkerResult?]
  var imageSize: CGSize = .zero
}
