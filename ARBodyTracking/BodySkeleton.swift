import ARKit
import Foundation
import RealityKit

class BodySkeleton: Entity {
    var joints: [String: Entity] = [:]
    var bones: [String: Entity] = [:]

    required init(for bodyAnchor: ARBodyAnchor) {
        super.init()

        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            let jointRadius: Float = 0.03
            let jointColor: UIColor = .green

            let jointEntity = makeJoint(radius: jointRadius, color: jointColor)
            joints[jointName] = jointEntity
            addChild(jointEntity)
        }

        for bone in Bone.allCases {
            guard let skeletonBone = makeSkeletonBone(bone: bone, bodyAnchor: bodyAnchor) else { continue }

            let boneEntity = makeBoneEntity(for: skeletonBone)
            bones[bone.name] = boneEntity
            addChild(boneEntity)
        }

        update(with: bodyAnchor)
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    func makeJoint(radius: Float, color: UIColor) -> Entity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])

        return modelEntity
    }

    func makeSkeletonBone(bone: Bone, bodyAnchor: ARBodyAnchor) -> SkeletonBone? {
        guard
            let fromJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointFromName)),
            let toJointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: bone.jointToName))
        else {
            return nil
        }

        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)
        let jointFromEntityOffsetFromRoot = simd_make_float3(fromJointEntityTransform.columns.3)
        let jointFromEntityPosition = rootPosition + jointFromEntityOffsetFromRoot
        let jointToEntityOffsetFromRoot = simd_make_float3(toJointEntityTransform.columns.3)
        let jointToEntityPosition = rootPosition + jointToEntityOffsetFromRoot

        let fromJoint = SkeletonJoint(name: bone.jointFromName, position: jointFromEntityPosition)
        let toJoint = SkeletonJoint(name: bone.jointToName, position: jointToEntityPosition)

        return SkeletonBone(fromJoint: fromJoint, toJoint: toJoint)
    }

    func makeBoneEntity(for skeletonBone: SkeletonBone, diameter: Float = 0.04, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateBox(size: [diameter, diameter, skeletonBone.length], cornerRadius: diameter / 2)
        let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])

        return entity
    }

    func update(with bodyAnchor: ARBodyAnchor) {
        let rootPosition = simd_make_float3(bodyAnchor.transform.columns.3)

        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointEntity = joints[jointName], let jointTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                let jointOffset = simd_make_float3(jointTransform.columns.3)
                jointEntity.position = rootPosition + jointOffset
                jointEntity.orientation = Transform(matrix: bodyAnchor.transform).rotation
            }
        }

        for bone in Bone.allCases {
            guard let entity = bones[bone.name], let skeletonBone = makeSkeletonBone(bone: bone, bodyAnchor: bodyAnchor) else { continue }

            entity.position = skeletonBone.centerPosition
            entity.look(at: skeletonBone.toJoint.position, from: skeletonBone.centerPosition, relativeTo: nil)
        }
    }
}
