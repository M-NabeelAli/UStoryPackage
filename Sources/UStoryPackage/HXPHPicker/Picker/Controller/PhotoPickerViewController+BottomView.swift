//
//  PhotoPickerViewController+BottomView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/27.
//

import Foundation

// MARK: PhotoPickerBottomViewDelegate
extension PhotoPickerViewController: PhotoPickerBottomViewDelegate {
    
    func bottomView(didEditButtonClick bottomView: PhotoPickerBottomView) {
//        guard let photoAsset = photoAsset(for: currentPreviewIndex) else {
//            return
//        }
//        openEditor(photoAsset)
        guard let picker = pickerController else { return }
        picker.pickerViewController?.openEditor(picker.selectedAssetArray[0], nil, picker.selectedAssetArray)
        
       // picker.previewViewController?.openEditor(picker.selectedAssetArray[0])
//        pushPreviewViewController(
//            previewAssets: picker.selectedAssetArray,
//            currentPreviewIndex: 0,
//            animated: true
//        )
        
        print("open editor from here")
    }
    
    func bottomView(
        didPreviewButtonClick bottomView: PhotoPickerBottomView
    ) {
        guard let picker = pickerController else { return }
        pushPreviewViewController(
            previewAssets: picker.selectedAssetArray,
            currentPreviewIndex: 0,
            animated: true
        )
    }
    func bottomView(
        didFinishButtonClick bottomView: PhotoPickerBottomView
    ) {
        pickerController?.finishCallback()
    }
    func bottomView(
        _ bottomView: PhotoPickerBottomView,
        didOriginalButtonClick isOriginal: Bool
    ) {
        pickerController?.originalButtonCallback()
    }
    
    public func setOriginal(_ isOriginal: Bool) {
        bottomView.boxControl.isSelected =  isOriginal
        if !isOriginal {
            // 取消
            bottomView.cancelRequestAssetFileSize()
        }else {
            // 选中
            bottomView.requestAssetBytes()
        }
        pickerController?.isOriginal = isOriginal
        pickerController?.originalButtonCallback()
    }
}
