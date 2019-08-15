//
//  UIImageExtensions.swift
//  Dynasty.dajiujiao
//
//  Created by uxiu.me on 2018/4/23.
//  Copyright © 2018年 HangZhouFaDaiGuoJiMaoYi Co. Ltd. All rights reserved.
//

import UIKit
import Accelerate

@objc extension UIImage {
    
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - imgName: <#imgName description#>
    ///   - bundleName: <#bundleName description#>
    /// - Returns: <#return value description#>
    public static func `init`(_ imgName: String, inBundle bundleName: String) -> UIImage? {
//        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
//        NSString *imgPath= [bundlePath stringByAppendingPathComponent:imgName];
//        UIImage *image=[UIImage imageWithContentsOfFile:imgPath];
//        return image;
        let tmpBundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle")
        guard let bundlePath = tmpBundlePath else {
            return nil
        }
        let tmpBundle = Bundle.init(path: bundlePath)
        guard let bundle = tmpBundle else {
            return nil
        }
        let tmpImagePath = bundle.path(forResource: imgName, ofType: "png")
        guard let imagePath = tmpImagePath else {
            return nil
        }
        let tmpImage = UIImage(contentsOfFile: imagePath)?.withRenderingMode(.alwaysOriginal)
        guard let image = tmpImage else {
            return nil
        }
        return image
    }
    
    
    
    /// 根据颜色创建一张纯色的图片
    ///
    /// - Parameter color: 颜色值
    /// - Returns: 返回一个UIImage实例
    public static func `init`(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    public func blur(level: CGFloat) -> UIImage {
        // 处理模糊程度, 防止超出
        var levelValue: CGFloat = level
        if level < 0 {
            levelValue = 0.1
        } else if level > 1.0 {
            levelValue = 1.0
        }
        
        // boxSize 必须大于 0
        var boxSize = Int(levelValue * 100)
        boxSize = boxSize - (boxSize % 2) + 1
        
        let cgImage = self.cgImage!
        
        // 图像缓存: 输入缓存、输出缓存
        var inBuffer = vImage_Buffer()
        var outBuffer = vImage_Buffer()
        var error = vImage_Error()
        
        
        let inProvider = cgImage.dataProvider
        let inBitmapData = inProvider?.data
        
        inBuffer.width = vImagePixelCount(cgImage.width)
        inBuffer.height = vImagePixelCount(cgImage.height)
        inBuffer.rowBytes = cgImage.bytesPerRow
        inBuffer.data = UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(inBitmapData!))
        
        // 像素缓存
        let pixelBuffer = malloc(cgImage.bytesPerRow * cgImage.height)
        outBuffer.data = pixelBuffer
        outBuffer.width = vImagePixelCount((cgImage.width))
        outBuffer.height = vImagePixelCount((cgImage.height))
        outBuffer.rowBytes = cgImage.bytesPerRow
        
        // 中间缓存区, 抗锯齿
        let pixelBuffer2 = malloc(cgImage.bytesPerRow * cgImage.height)
        var outBuffer2 = vImage_Buffer()
        outBuffer2.data = pixelBuffer2
        outBuffer2.width = vImagePixelCount(cgImage.width)
        outBuffer2.height = vImagePixelCount(cgImage.height)
        outBuffer2.rowBytes = cgImage.bytesPerRow
        
        error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, nil, 0, 0, UInt32(boxSize), UInt32(boxSize), nil, vImage_Flags(kvImageEdgeExtend))
        error = vImageBoxConvolve_ARGB8888(&outBuffer2, &outBuffer, nil, 0, 0, UInt32(boxSize), UInt32(boxSize), nil, vImage_Flags(kvImageEdgeExtend))
        
        
        if error != kvImageNoError {
            debugPrint(error)
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: outBuffer.data, width: Int(outBuffer.width), height: Int(outBuffer.height), bitsPerComponent: 8, bytesPerRow: outBuffer.rowBytes, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue)
        
        let finalCGImage = context!.makeImage()
        let finalImage = UIImage(cgImage: finalCGImage!)
        
        free(pixelBuffer!)
        free(pixelBuffer2!)
        
        return finalImage
    }
    
}
