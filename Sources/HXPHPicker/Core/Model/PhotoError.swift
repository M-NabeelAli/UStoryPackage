//
//  PhotoError.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public enum PhotoError: LocalizedError {
    
    public enum `Type` {
        case imageEmpty
        case videoEmpty
        case exportFailed
    }
    
    case error(type: Type, message: String)
}

extension PhotoError {
    public var errorDescription: String? {
        switch self {
        case let .error(_, message):
            return message
        }
    }
}

public enum AssetError: Error {
    /// Failed to write file
    case fileWriteFailed
    /// export failed
    case exportFailed(Error?)
    /// Invalid Data
    case invalidData
    /// invalid edit data
    case invalidEditedData
    /// phAsse invalid
    case invalidPHAsset
    /// network address is empty
    case networkURLIsEmpty
    /// local address is empty
    case localURLIsEmpty
    /// Local LivePhoto is empty
    case localLivePhotoIsEmpty
    /// Type error, for example: it is .photo but to get videoURL
    case typeError
    /// Failed to obtain data from the system album, [AnyHashable: Any]?: Information that the system failed to obtain
    case requestFailed([AnyHashable: Any]?)
    /// Need to sync resources on iCloud
    case needSyncICloud
    /// Sync iCloud failed
    case syncICloudFailed([AnyHashable: Any]?)
    /// There are other files at the specified address, and an error occurred when deleting the existing file
    case removeFileFailed
    /// PHAssetResource 为空
    case assetResourceIsEmpty
    /// PHAssetResource写入数据错误
    case assetResourceWriteDataFailed(Error)
    /// 导出livePhoto里的图片地址失败
    case exportLivePhotoImageURLFailed(Error?)
    /// 导出livePhoto里的视频地址失败
    case exportLivePhotoVideoURLFailed(Error?)
    /// 导出livePhoto里的地址失败（图片失败信息,视频失败信息）
    case exportLivePhotoURLFailed(Error?, Error?)
    /// 图片压缩失败
    case imageCompressionFailed
    /// 视频下载失败
    case videoDownloadFailed
    /// 本地livePhoto取消写入
    case localLivePhotoCancelWrite
    /// 本地livePhoto图片写入失败
    case localLivePhotoWriteImageFailed
    /// 本地livePhoto视频写入失败
    case localLivePhotoWriteVideoFailed
    /// 本地livePhoto合成失败
    case localLivePhotoRequestFailed
}
