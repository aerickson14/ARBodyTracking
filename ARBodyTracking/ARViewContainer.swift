import ARKit
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        setupForBodyTracking(in: arView, with: context.coordinator)

        arView.scene.addAnchor(context.coordinator.bodySkeletonAnchor)

        return arView
    }

    func updateUIView(_: ARView, context _: Context) {}

    private func setupForBodyTracking(in arView: ARView, with coordinator: Coordinator) {
        let config = ARBodyTrackingConfiguration()
        arView.session.run(config)
        arView.session.delegate = coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var bodySkeleton: BodySkeleton?
        var bodySkeletonAnchor = AnchorEntity()

        public func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let bodyAnchor = anchor as? ARBodyAnchor {
                    if let skeleton = bodySkeleton {
                        skeleton.update(with: bodyAnchor)
                    } else {
                        let skeleton = BodySkeleton(for: bodyAnchor)
                        bodySkeleton = skeleton
                        bodySkeletonAnchor.addChild(skeleton)
                    }
                }
            }
        }
    }
}
