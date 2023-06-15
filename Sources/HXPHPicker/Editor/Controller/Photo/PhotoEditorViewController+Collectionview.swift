//
//  PhotoEditorPreviewViewController+Collectionview.swift
//  ustories
//
//  Created by imac3 on 14/06/2023.
//

import Foundation
import UIKit

// MARK: UICollectionViewDataSource
extension PhotoEditorViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetCount
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        guard let photoAsset = photoAsset(for: indexPath.item) else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: NSStringFromClass(PreviewPhotoViewCell.self),
                for: indexPath)
        }
        
        let cell: PhotoEditorPreviewCell
        
        if photoAsset.mediaType == .photo {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NSStringFromClass(PhotoEditorPreviewCell.self),
                for: indexPath
            ) as! PhotoEditorPreviewCell
            cell.photoAsset = photoAsset
            cell.delegate = self
            return cell
//            if photoAsset.mediaSubType == .livePhoto ||
//                photoAsset.mediaSubType == .localLivePhoto {
//                cell = collectionView.dequeueReusableCell(
//                    withReuseIdentifier: NSStringFromClass(PreviewLivePhotoViewCell.self),
//                    for: indexPath
//                ) as! PreviewLivePhotoViewCell
//                let livePhotoCell = cell as! PreviewLivePhotoViewCell
//                livePhotoCell.livePhotoPlayType = configPreview.livePhotoPlayType
//                livePhotoCell.liveMarkConfig = configPreview.livePhotoMark
//
//            }else {
//                cell = collectionView.dequeueReusableCell(
//                    withReuseIdentifier: NSStringFromClass(PreviewPhotoViewCell.self),
//                    for: indexPath
//                ) as! PreviewPhotoViewCell
//            }
        }
//        else {
//            cell = collectionView.dequeueReusableCell(
//                withReuseIdentifier: NSStringFromClass(PreviewVideoViewCell.self),
//                for: indexPath
//            ) as! PreviewVideoViewCell
//            let videoCell = cell as! PreviewVideoViewCell
//            videoCell.videoPlayType = configPreview.videoPlayType
//            videoCell.statusBarShouldBeHidden = statusBarShouldBeHidden
//        }
        
        
        
     //   cellForIndex?(cell, indexPath.item, currentPreviewIndex)
        return UICollectionViewCell()
    }
}
// MARK: UICollectionViewDelegate
extension PhotoEditorViewController: UICollectionViewDelegate {
    
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as! PhotoEditorPreviewCell
       // myCell.scrollContentView.startAnimatedImage()
        if myCell.photoAsset.mediaType == .video {
          //  myCell.scrollView.zoomScale = 1
        }
        if let pickerController = pickerController {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewCellWillDisplay: myCell.photoAsset,
                at: indexPath.item
            )
        }
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as! PhotoEditorPreviewCell
        myCell.cancelRequest()
        if let pickerController = pickerController {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewCellDidEndDisplaying: myCell.photoAsset,
                at: indexPath.item
            )
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        let offsetX = scrollView.contentOffset.x  + (view.width + 20) * 0.5
        let viewWidth = view.width + 20
        var currentIndex = Int(offsetX / viewWidth)
        if currentIndex > assetCount - 1 {
            currentIndex = assetCount - 1
        }
        if currentIndex < 0 {
            currentIndex = 0
        }
        if let photoAsset = photoAsset(for: currentIndex) {
            if !isExternalPreview {
                if photoAsset.mediaType == .video && videoLoadSingleCell {
//                    selectBoxControl.isHidden = true
//                    selectBoxControl.isEnabled = false
                }else {
//                    selectBoxControl.isHidden = false
//                    selectBoxControl.isEnabled = true
//                    updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
//                    selectBoxControl.isSelected = photoAsset.isSelected
                }
            }
            if !firstLayoutSubviews &&
                configPreview.bottomView.showSelectedView &&
                (isMultipleSelect || isExternalPreview) &&
                configPreview.showBottomView {
//                bottomView.selectedView.scrollTo(photoAsset: photoAsset)
            }
//            #if HXPICKER_ENABLE_EDITOR
            if let pickerController = pickerController,
               !configPreview.bottomView.editButtonHidden,
               configPreview.showBottomView {
                if photoAsset.mediaType == .photo {
//                    bottomView.editBtn.isEnabled = pickerController.configPreview.editorOptions.isPhoto
                }else if photoAsset.mediaType == .video {
//                    bottomView.editBtn.isEnabled = pickerController.configPreview.editorOptions.contains(.video)
                }
            }
//            #endif
            pickerController?.previewUpdateCurrentlyDisplayedAsset(photoAsset: photoAsset, index: currentIndex)
        }
        //self.currentPreviewIndex = currentIndex
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        if scrollView.isTracking {
            return
        }
        let cell = getCell(for: currentPreviewIndex)
        cell?.requestPreviewAsset()
        if let pickerController = pickerController, let cell = cell {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewDidEndDecelerating: cell.photoAsset,
                at: currentPreviewIndex
            )
        }
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = getEditorCell(for: indexPath.row){
            
            cell.delegate?.bottomView(didSelectedItemAt: cell.photoAsset)
        }
    }
}

// MARK: PhotoPreviewViewCellDelegate
//extension PhotoEditorViewController: PhotoPreviewViewCellDelegate {
//    func cell(requestSucceed cell: PhotoPreviewViewCell) {
////        delegate?.previewViewController(self, requestSucceed: cell.photoAsset)
//    }
//    func cell(requestFailed cell: PhotoPreviewViewCell) {
////        delegate?.previewViewController(self, requestFailed: cell.photoAsset)
//    }
//    func cell(singleTap cell: PhotoPreviewViewCell) {
//        if navigationController == nil {
//            return
//        }
//        let isHidden = navigationController!.navigationBar.isHidden
//        statusBarShouldBeHidden = !isHidden
//        if self.modalPresentationStyle == .fullScreen {
//            navigationController?.setNeedsStatusBarAppearanceUpdate()
//        }
//        navigationController!.setNavigationBarHidden(statusBarShouldBeHidden, animated: true)
//        let currentCell = getCell(for: currentPreviewIndex)
//        currentCell?.statusBarShouldBeHidden = statusBarShouldBeHidden
//        let videoCell = currentCell as? PreviewVideoViewCell
//        if !statusBarShouldBeHidden {
//            if configPreview.showBottomView {
//                bottomView.isHidden = false
//            }
//            if currentCell?.photoAsset.mediaType == .video && configPreview.singleClickCellAutoPlayVideo {
//                currentCell?.scrollContentView.videoView.stopPlay()
//            }
//            videoCell?.showToolView()
//            if let liveCell = currentCell as? PreviewLivePhotoViewCell {
//                liveCell.showMark()
//            }
//        }else {
//            if currentCell?.photoAsset.mediaType == .video && configPreview.singleClickCellAutoPlayVideo {
//                currentCell?.scrollContentView.videoView.startPlay()
//            }
//            videoCell?.hideToolView()
//            if let liveCell = currentCell as? PreviewLivePhotoViewCell {
//                liveCell.hideMark()
//            }
//        }
//        if configPreview.showBottomView {
//            UIView.animate(withDuration: 0.25) {
//                self.bottomView.alpha = self.statusBarShouldBeHidden ? 0 : 1
//            } completion: { (finish) in
//                self.bottomView.isHidden = self.statusBarShouldBeHidden
//            }
//        }
//        if let pickerController = pickerController {
//            pickerController.pickerDelegate?.pickerController(
//                pickerController,
//                previewSingleClick: cell.photoAsset,
//                atIndex: currentPreviewIndex
//            )
//        }
//    }
//    func cell(longPress cell: PhotoPreviewViewCell) {
//        if let pickerController = pickerController {
//            pickerController.pickerDelegate?.pickerController(
//                pickerController,
//                previewLongPressClick: cell.photoAsset,
//                atIndex: currentPreviewIndex
//            )
//        }
//    }
//
//    func photoCell(networkImagedownloadSuccess photoCell: PhotoPreviewViewCell) {
//        #if canImport(Kingfisher)
//        if let pickerController = pickerController,
//           let index = collectionView.indexPath(for: photoCell)?.item {
//            pickerController.pickerDelegate?.pickerController(
//                pickerController,
//                previewNetworkImageDownloadSuccess: photoCell.photoAsset,
//                atIndex: index
//            )
//        }
//        delegate?.previewViewController(self, networkImagedownloadSuccess: photoCell.photoAsset)
//        if configPreview.showBottomView {
//            bottomView.requestAssetBytes()
//        }
//        #endif
//    }
//
//    func photoCell(networkImagedownloadFailed photoCell: PhotoPreviewViewCell) {
//        #if canImport(Kingfisher)
//        if let pickerController = pickerController,
//           let index = collectionView.indexPath(for: photoCell)?.item {
//            pickerController.pickerDelegate?.pickerController(
//                pickerController,
//                previewNetworkImageDownloadFailed: photoCell.photoAsset,
//                atIndex: index
//            )
//        }
//        #endif
//    }
//}
