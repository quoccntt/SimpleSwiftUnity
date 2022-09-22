//
//  ViewController.swift
//  simpleIOS
//
//  Created by QuocNP1.APL on 20/09/2022.
//

import UnityFramework

class UnityEmbeddedSwift: UIResponder, UIApplicationDelegate, UnityFrameworkListener {

    private struct UnityMessage {
        let objectName: String?
        let methodName: String?
        let messageBody: String?
    }

    private static var instance: UnityEmbeddedSwift!
    private var unityFrameWork: UnityFramework!
    static var hostMainWindow: UIWindow! // Window to return to when exiting Unity window
    private static var launchOpts: [UIApplication.LaunchOptionsKey: Any]?

    private static var cachedMessages = [UnityMessage]()

    // MARK: - Static functions (that can be called from other scripts)

    static func getUnityRootViewController() -> UIViewController! {
        return instance.unityFrameWork.appController()?.rootViewController
    }

    static func getUnityView() -> UIView! {
        return instance.unityFrameWork.appController()?.rootView
    }
    
    static func addUnityWindow() -> UIWindow? {
        hostMainWindow = instance.unityFrameWork.appController().window
        return hostMainWindow
    }

    static func unityWindow() -> UIWindow? {
        return instance.unityFrameWork.appController().window
    }

    static func setHostMainWindow(_ hostMainWindow: UIWindow?) {
        UnityEmbeddedSwift.hostMainWindow = hostMainWindow
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }

    static func setLaunchinOptions(_ launchingOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        UnityEmbeddedSwift.launchOpts = launchingOptions
    }

    static func showUnity() {
        if UnityEmbeddedSwift.instance == nil || UnityEmbeddedSwift.instance.unityIsInitialized() == false {
            UnityEmbeddedSwift().initUnityWindow()
        } else {
            UnityEmbeddedSwift.instance.showUnityWindow()
        }
    }

    static func hideUnity() {
        UnityEmbeddedSwift.instance?.hideUnityWindow()
    }

    static func pauseUnity() {
        UnityEmbeddedSwift.instance?.pauseUnityWindow()
    }

    static func unpauseUnity() {
        UnityEmbeddedSwift.instance?.unpauseUnityWindow()
    }

    static func unloadUnity() {
        UnityEmbeddedSwift.instance?.unloadUnityWindow()
    }

    static func sendUnityMessage(objectName: String, methodName: String, message: String) {
        let msg: UnityMessage = UnityMessage(objectName: objectName, methodName: methodName, messageBody: message)

        // Send the message right away if Unity is initialized, else cache it
        if UnityEmbeddedSwift.instance != nil && UnityEmbeddedSwift.instance.unityIsInitialized() {
            UnityEmbeddedSwift.instance.unityFrameWork.sendMessageToGO(withName: msg.objectName,
                                                            functionName: msg.methodName,
                                                            message: msg.messageBody)
        } else {
            UnityEmbeddedSwift.cachedMessages.append(msg)
        }
    }

    // MARK: Callback from UnityFrameworkListener

    func unityDidUnload(_ notification: Notification!) {
        unityFrameWork.unregisterFrameworkListener(self)
        unityFrameWork = nil
        UnityEmbeddedSwift.hostMainWindow?.makeKeyAndVisible()
    }

    // MARK: - Private functions (called within the class)

    private func unityIsInitialized() -> Bool {
        return unityFrameWork != nil && (unityFrameWork.appController() != nil)
    }

    private func initUnityWindow() {
        if unityIsInitialized() {
            showUnityWindow()
            return
        }

        unityFrameWork = unityFrameworkLoad()!
        unityFrameWork.setDataBundleId("com.unity3d.framework")
        unityFrameWork.register(self)
        //        NSClassFromString("FrameworkLibAPI")?.registerAPIforNativeCalls(self)

        unityFrameWork.runEmbedded(withArgc: CommandLine.argc,
                        argv: CommandLine.unsafeArgv,
                        appLaunchOpts: UnityEmbeddedSwift.launchOpts)

        sendUnityMessageToGameObject()

        UnityEmbeddedSwift.instance = self
    }

    private func showUnityWindow() {
        if unityIsInitialized() {
            unityFrameWork.showUnityWindow()
            sendUnityMessageToGameObject()
        }
    }

    private func hideUnityWindow() {
        if UnityEmbeddedSwift.hostMainWindow == nil {
            print("WARNING: hostMainWindow is nil! Cannot switch from Unity window to previous window")
        } else {
            UnityEmbeddedSwift.hostMainWindow?.makeKeyAndVisible()
        }
    }

    private func pauseUnityWindow() {
        unityFrameWork.pause(true)
    }

    private func unpauseUnityWindow() {
        unityFrameWork.pause(false)
    }

    private func unloadUnityWindow() {
        if unityIsInitialized() {
            UnityEmbeddedSwift.cachedMessages.removeAll()
            unityFrameWork.unloadApplication()
        }
    }

    private func sendUnityMessageToGameObject() {
        if UnityEmbeddedSwift.cachedMessages.count >= 0 && unityIsInitialized() {
            for msg in UnityEmbeddedSwift.cachedMessages {
                unityFrameWork.sendMessageToGO(withName: msg.objectName,
                                               functionName: msg.methodName,
                                               message: msg.messageBody)
            }
            UnityEmbeddedSwift.cachedMessages.removeAll()
        }
    }

    private func unityFrameworkLoad() -> UnityFramework? {
        let bundlePath: String = Bundle.main.bundlePath + "/Frameworks/UnityFramework.framework"

        let bundle = Bundle(path: bundlePath )
        if bundle?.isLoaded == false {
            bundle?.load()
        }

        let ufw = bundle?.principalClass?.getInstance()
        if ufw?.appController() == nil {
            // unity is not initialized
            //            ufw?.executeHeader = &mh_execute_header

            let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
            machineHeader.pointee = _mh_execute_header

            ufw!.setExecuteHeader(machineHeader)
        }
        return ufw
    }
}

