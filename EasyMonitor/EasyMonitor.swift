//
//  EasyMonitor.swift
//  LiangRenMall
//
//  Created by 荣浩 on 16/8/17.
//  Copyright © 2016年 LiangRen. All rights reserved.
//

import UIKit

public class EasyMonitor: NSObject {
    private var runloopActivity: CFRunLoopActivity?
    private var timeoutCount: Int = 0
    private let dispatchSemaphore = dispatch_semaphore_create(0)
    
    public static var sharedInstance = EasyMonitor()

//MARK: - public method
    public func startMonitor() {
        addObserver()
        print("开始监控！！！")
        startObserver {
            self.waitSemaphore(nil, failHandle: { 
                if self.isInEventloop() == true {
                    if self.timeoutCount > 3 {
                        print("卡顿！！！")
                        self.printStackInfo()
                        self.timeoutCount = 0
                    }
                    else {
                        self.timeoutCount += 1
                    }
                }
            })
        }
    }
    
    public func endMonitor() {
        
        
    }
    
//MARK: - callback
    private func observerCallbackFunc() -> CFRunLoopObserverCallBack {
        return {(observer, activity, context) -> Void in
            let _self = UnsafePointer<EasyMonitor>(context).memory
            _self.runloopActivity = activity
            dispatch_semaphore_signal(_self.dispatchSemaphore)
            
            switch activity {
            case CFRunLoopActivity.AfterWaiting:
                _self.timeoutCount = 0
            default:
                break
            }
        }
    }
    
//MARK: - private method
    private func addObserver() {
        var observerContext = CFRunLoopObserverContext(version: 0, info: &EasyMonitor.sharedInstance, retain: nil, release: nil, copyDescription: nil)
        let runLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault, CFRunLoopActivity.AllActivities.rawValue, true, 0, observerCallbackFunc(), &observerContext)
        CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopObserver, kCFRunLoopCommonModes)
    }
    
    private func startObserver(observerHandle: ()->Void) {
        let monitorQueue = dispatch_queue_create("com.Monitor", nil)
        dispatch_async(monitorQueue) {
            while true {
                observerHandle()
            }
        }
    }
    
    private func waitSemaphore(successHandle: (()->Void)?, failHandle: ()->Void) {
        let semaphoreWait = dispatch_semaphore_wait(self.dispatchSemaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * Int64(NSEC_PER_MSEC)))
        if semaphoreWait != 0 {
            failHandle()
        }
        else {
            if successHandle != nil {
                successHandle!()
            }
        }
    }
    
    private func isInEventloop() ->Bool {
        if self.runloopActivity == CFRunLoopActivity.BeforeTimers
            || self.runloopActivity == CFRunLoopActivity.BeforeSources
            || self.runloopActivity == CFRunLoopActivity.AfterWaiting {
            return true
        }
        return false
    }
    
    private func printStackInfo() {
//        let config = PLCrashReporterConfig(signalHandlerType: .BSD, symbolicationStrategy: .All)
//        let reporter = PLCrashReporter(configuration: config)
//        do {
//            let report = try PLCrashReport(data: reporter.generateLiveReport())
//            let ss = PLCrashReportTextFormatter.stringValueForCrashReport(report, withTextFormat: PLCrashReportTextFormatiOS)
//            print(ss)
//        }
//        catch {
//            
//        }
    }
}
