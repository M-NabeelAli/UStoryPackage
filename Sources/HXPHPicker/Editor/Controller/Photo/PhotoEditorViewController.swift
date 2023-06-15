//
//  PhotoEditorViewController.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit
import Photos

#if canImport(Kingfisher)
import Kingfisher
#endif
#if canImport(Harbeth)
import Harbeth
#endif

open class PhotoEditorViewController: BaseViewController {
    
    
    //MARK: - bottom images Preview
    
    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = false
        }
        //        collectionView.register(
        //            PreviewPhotoViewCell.self,
        //            forCellWithReuseIdentifier: NSStringFromClass(PreviewPhotoViewCell.self)
        //        )
        //        collectionView.register(
        //            PreviewLivePhotoViewCell.self,
        //            forCellWithReuseIdentifier: NSStringFromClass(PreviewLivePhotoViewCell.self)
        //        )
        //        if let customVideoCell = config.customVideoCellClass {
        //            collectionView.register(
        //                customVideoCell,
        //                forCellWithReuseIdentifier: NSStringFromClass(PreviewVideoViewCell.self)
        //            )
        //        }else {
        collectionView.register(
            PhotoEditorPreviewCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(PhotoEditorPreviewCell.self)
        )
        //        }
        return collectionView
    }()
    
    public var previewAssets: [PhotoAsset] = []
    
    var assetCount: Int {
        if previewAssets.isEmpty {
            return numberOfPages?() ?? 0
        }
        return previewAssets.count
    }
    var numberOfPages: PhotoBrowser.NumberOfPagesHandler?
    var cellForIndex: PhotoBrowser.CellReloadContext?
    var assetForIndex: PhotoBrowser.RequiredAsset?
    public var configPreview: PreviewViewConfiguration
    var isExternalPickerPreview: Bool = false
    var orientationDidChange: Bool = false
    var statusBarShouldBeHidden: Bool = false
    var videoLoadSingleCell = false
    var viewDidAppear: Bool = false
    var firstLayoutSubviews: Bool = true
    public var currentPreviewIndex: Int = 0
    public var isExternalPreview: Bool = false
    var isMultipleSelect: Bool = false
    var allowLoadPhotoLibrary: Bool = true
    
    //    lazy var bottomView: PhotoPickerBottomView = {
    //        let bottomView = PhotoPickerBottomView(
    //            config: configPreview.bottomView,
    //            allowLoadPhotoLibrary: allowLoadPhotoLibrary,
    //            isMultipleSelect: isMultipleSelect,
    //            sourceType: isExternalPreview ? .browser : .preview
    //        )
    //        bottomView.hx_delegate = self
    //        if configPreview.bottomView.showSelectedView && (isMultipleSelect || isExternalPreview) {
    //            bottomView.selectedView.reloadData(
    //                photoAssets: pickerController!.selectedAssetArray
    //            )
    //        }
    //        if !isExternalPreview {
    //            bottomView.boxControl.isSelected = pickerController!.isOriginal
    //            bottomView.requestAssetBytes()
    //        }
    //       // bottomView.backgroundColor = .red
    //        return bottomView
    //    }()
    
    lazy var bottomBGV: UIView = {
        return bottomBGV
    }()
    
    lazy var publishBGV: UIView = {
        return publishBGV
    }()
    
    lazy var finishBtn: UIButton = {
        let finishBtn = UIButton.init(type: .custom)
        finishBtn.setTitle("Publish".localized, for: .normal)
        finishBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        finishBtn.layer.cornerRadius = 3
        finishBtn.layer.masksToBounds = true
        finishBtn.isEnabled = false
        finishBtn.tag = 1 //1 for next screen // 2 for completion
        finishBtn.addTarget(self, action: #selector(didFinishButtonClick(button:)), for: .touchUpInside)
        return finishBtn
    }()
    @objc func didFinishButtonClick(button: UIButton) {
        if button.tag == 1 {
            
            //            hx_delegate?.bottomView(didEditButtonClick: self)
        }
        else{
            //            hx_delegate?.bottomView(didFinishButtonClick: self)
        }
        
    }
    
    func updateFinishButtonFrame() {
        
        var finishWidth: CGFloat = finishBtn.currentTitle!.localized.width(
            ofFont: finishBtn.titleLabel!.font,
            maxHeight: 50
        ) + 20
        if finishWidth < 60 {
            finishWidth = 60
        }
        finishBtn.frame = CGRect(
            x: bottomBGV.width - UIDevice.rightMargin - finishWidth - 12,
            y: 0,
            width: finishWidth,
            height: 33
        )
        finishBtn.centerY = 25
    }
    public weak var delegate: PhotoEditorViewControllerDelegate?
    
    /// 配置
    public let config: PhotoEditorConfiguration
    
    /// 当前编辑的图片
    public private(set) var image: UIImage!
    
    /// 来源
    public var sourceType: EditorController.SourceType
    
    /// 当前编辑状态
    public var state: State { pState }
    
    /// 上一次的编辑结果
    public var editResult: PhotoEditResult?
    
    /// 确认/取消之后自动退出界面
    public var autoBack: Bool = true
    
    public var finishHandler: FinishHandler?
    
    public var cancelHandler: CancelHandler?
    
    public typealias FinishHandler = (PhotoEditorViewController, PhotoEditResult?) -> Void
    public typealias CancelHandler = (PhotoEditorViewController) -> Void
    
    /// 编辑image
    /// - Parameters:
    ///   - image: 对应的 UIImage
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(
        image: UIImage,
        editResult: PhotoEditResult? = nil,
        config: PhotoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .local
        self.image = image
        self.config = config
        self.editResult = editResult
        self.configPreview = PreviewViewConfiguration()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = config.modalPresentationStyle
    }
    
    //    #if HXPICKER_ENABLE_PICKER
    /// 当前编辑的PhotoAsset对象
    public var photoAsset: PhotoAsset!
    
    /// 编辑 PhotoAsset
    /// - Parameters:
    ///   - photoAsset: 对应数据的 PhotoAsset
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(
        photoAsset: PhotoAsset,
        editResult: PhotoEditResult? = nil,
        config: PhotoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .picker
        requestType = 1
        needRequest = true
        self.config = config
        self.editResult = editResult
        self.photoAsset = photoAsset
        self.configPreview = PreviewViewConfiguration()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = config.modalPresentationStyle
    }
    //    #endif
    
#if canImport(Kingfisher)
    /// 当前编辑的网络图片地址
    public private(set) var networkImageURL: URL?
    
    /// 编辑网络图片
    /// - Parameters:
    ///   - networkImageURL: 对应的网络地址
    ///   - editResult: 上一次编辑结果
    ///   - config: 编辑配置
    public init(
        networkImageURL: URL,
        editResult: PhotoEditResult? = nil,
        config: PhotoEditorConfiguration
    ) {
        PhotoManager.shared.appearanceStyle = config.appearanceStyle
        PhotoManager.shared.createLanguageBundle(languageType: config.languageType)
        sourceType = .network
        requestType = 2
        needRequest = true
        self.networkImageURL = networkImageURL
        self.config = config
        self.editResult = editResult
        self.configPreview = PreviewViewConfiguration()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = config.modalPresentationStyle
    }
#endif
    var pState: State = .normal
    var filterHDImage: UIImage?
    var mosaicImage: UIImage?
    
#if canImport(Harbeth)
    var metalFilters: [PhotoEditorFilterEditModel.`Type`: C7FilterProtocol] = [:]
#endif
    
    var thumbnailImage: UIImage!
    
    var transitionalImage: UIImage?
    var transitionCompletion: Bool = true
    var isFinishedBack: Bool = false
     var needRequest: Bool = false
     var requestType: Int = 0
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var imageView: PhotoEditorView = {
        let imageView = PhotoEditorView(
            editType: .image,
            cropConfig: config.cropping,
            mosaicConfig: config.mosaic,
            brushConfig: config.brush,
            exportScale: config.scale,
            urlConfig: config.imageURLConfig
        )
        imageView.editorDelegate = self
        return imageView
    }()
    var topViewIsHidden: Bool = false
    @objc func singleTap() {
        if state == .cropping {
            return
        }
        imageView.deselectedSticker()
        func resetOtherOption() {
            if let option = currentToolOption {
                if option.type == .graffiti {
                    imageView.drawEnabled = true
                }else if option.type == .mosaic {
                    imageView.mosaicEnabled = true
                }
            }
            showTopView()
        }
        if let type = currentToolOption?.type {
            if type == .filter {
                if isShowFilterParameter {
                    hideFilterParameterView()
                    return
                }
                currentToolOption = nil
                resetOtherOption()
                hiddenFilterView()
                imageView.canLookOriginal = false
                return
            }else if type == .chartlet {
                currentToolOption = nil
                imageView.isEnabled = true
                resetOtherOption()
                hiddenChartletView()
                return
            }
        }
        if topViewIsHidden {
            showTopView()
        }else {
            hidenTopView()
        }
    }
    
    func configButtonColor(){
        
        
        finishBtn.setTitleColor(
            PhotoManager.isDark ?
                .white :
                    .white,
            for: .normal
        )
        finishBtn.setTitleColor(
            PhotoManager.isDark ?
                .white :
                    .white,
            for: .disabled
        )
        finishBtn.setBackgroundImage(
            UIImage.image(
                for: .green,
                havingSize: CGSize.zero
            ),
            for: .normal
        )
        finishBtn.setBackgroundImage(
            UIImage.image(
                for: PhotoManager.isDark ?
                    .green.withAlphaComponent(0.5) :
                        .green.withAlphaComponent(0.5),
                havingSize: CGSize.zero
            ),
            for: .disabled
        )
        
    }
    /// 裁剪确认视图
    public lazy var cropConfirmView: EditorCropConfirmView = {
        let cropConfirmView = EditorCropConfirmView.init(config: config.cropConfimView, showReset: true)
        cropConfirmView.alpha = 0
        cropConfirmView.isHidden = true
        cropConfirmView.delegate = self
        return cropConfirmView
    }()
    public lazy var editorToolView: EditorToolView = {
        let toolView = EditorToolView.init(config: config.toolView)
        toolView.delegate = self
        return toolView
    }()
    
    public lazy var topView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        view.addSubview(cancelBtn)
        return view
    }()
    
    public lazy var cancelBtn: UIButton = {
        let cancelBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 57, height: 44))
        cancelBtn.setImage(UIImage.image(for: config.backButtonImageName), for: .normal)
        cancelBtn.addTarget(self, action: #selector(didBackButtonClick), for: .touchUpInside)
        return cancelBtn
    }()
    
    @objc func didBackButtonClick() {
        transitionalImage = image
        cancelHandler?(self)
        didBackClick(true)
    }
    
    func didBackClick(_ isCancel: Bool = false) {
        imageView.imageResizerView.stopShowMaskBgTimer()
        if let type = currentToolOption?.type {
            switch type {
            case .graffiti:
                hiddenBrushColorView()
            case .mosaic:
                hiddenMosaicToolView()
            default:
                break
            }
        }
        if isCancel {
            delegate?.photoEditorViewController(didCancel: self)
        }
        if autoBack {
            if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            }else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    public lazy var topMaskLayer: CAGradientLayer = {
        let layer = PhotoTools.getGradientShadowLayer(true)
        return layer
    }()
    lazy var brushBlockView: PhotoEditorBrushSizeView = {
        let view = PhotoEditorBrushSizeView.init(frame: .init(x: 0, y: 0, width: 30, height: 200))
        view.alpha = 0
        view.isHidden = true
        view.value = config.brush.lineWidth / (config.brush.maximumLinewidth - config.brush.minimumLinewidth)
        view.blockBeganChanged = { [weak self] _ in
            guard let self = self else { return }
            let lineWidth = self.imageView.brushLineWidth + 4
            self.brushSizeView.size = CGSize(width: lineWidth, height: lineWidth)
            self.brushSizeView.center = CGPoint(x: self.view.width * 0.5, y: self.view.height * 0.5)
            self.brushSizeView.alpha = 0
            self.view.addSubview(self.brushSizeView)
            UIView.animate(withDuration: 0.2) {
                self.brushSizeView.alpha = 1
            }
        }
        view.blockDidChanged = { [weak self] in
            guard let self = self else { return }
            let config = self.config.brush
            let lineWidth = (
                config.maximumLinewidth -  config.minimumLinewidth
            ) * $0 + config.minimumLinewidth
            self.imageView.brushLineWidth = lineWidth
            self.brushSizeView.size = CGSize(width: lineWidth + 4, height: lineWidth + 4)
            self.brushSizeView.center = CGPoint(x: self.view.width * 0.5, y: self.view.height * 0.5)
        }
        view.blockEndedChanged = { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2) {
                self.brushSizeView.alpha = 0
            } completion: { _ in
                self.brushSizeView.removeFromSuperview()
            }
        }
        return view
    }()
    lazy var brushSizeView: BrushSizeView = {
        let lineWidth = imageView.brushLineWidth + 4
        let view = BrushSizeView(frame: CGRect(origin: .zero, size: CGSize(width: lineWidth, height: lineWidth)))
        return view
    }()
    public lazy var brushColorView: PhotoEditorBrushColorView = {
        let view = PhotoEditorBrushColorView(config: config.brush)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    lazy var chartletView: EditorChartletView = {
        let view = EditorChartletView(
            config: config.chartlet,
            editorType: .photo
        )
        view.delegate = self
        
        return view
    }()
    
    public lazy var cropToolView: PhotoEditorCropToolView = {
        var showRatios = true
        if config.cropping.aspectRatios.isEmpty || config.cropping.isRoundCrop {
            showRatios = false
        }
        let view = PhotoEditorCropToolView(
            showRatios: showRatios,
            scaleArray: config.cropping.aspectRatios,
            defaultSelectedIndex: config.cropping.defaultSeletedIndex
        )
        view.delegate = self
        view.themeColor = config.cropping.aspectRatioSelectedColor
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    lazy var mosaicToolView: PhotoEditorMosaicToolView = {
        let view = PhotoEditorMosaicToolView(selectedColor: config.toolView.toolSelectedColor)
        view.delegate = self
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    var filterImage: UIImage?
    lazy var filterView: PhotoEditorFilterView = {
        let view = PhotoEditorFilterView(
            filterConfig: config.filter,
            hasLastFilter: editResult?.editedData.hasFilter ?? false
        )
        view.delegate = self
        return view
    }()
    var isShowFilterParameter = false
    lazy var filterParameterView: PhotoEditorFilterParameterView = {
        let view = PhotoEditorFilterParameterView(sliderColor: config.filter.selectedColor)
        view.delegate = self
        return view
    }()
    
    var imageInitializeCompletion = false
    var imageViewDidChange: Bool = true
    var currentToolOption: EditorToolOptions?
    var toolOptions: EditorToolView.Options = []
    open override func viewDidLoad() {
        
        super.viewDidLoad()
        for options in config.toolView.toolOptions {
            switch options.type {
            case .graffiti:
                toolOptions.insert(.graffiti)
            case .chartlet:
                toolOptions.insert(.chartlet)
            case .text:
                toolOptions.insert(.text)
            case .cropSize:
                toolOptions.insert(.cropSize)
            case .mosaic:
                toolOptions.insert(.mosaic)
            case .filter:
                toolOptions.insert(.filter)
            case .music:
                toolOptions.insert(.music)
            default:
                break
            }
        }
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleTap))
        singleTap.delegate = self
        view.addGestureRecognizer(singleTap)
        view.isExclusiveTouch = true
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.addSubview(imageView)
        topView.addSubview(editorToolView)
        
        if toolOptions.contains(.cropSize) {
            view.addSubview(cropConfirmView)
            view.addSubview(cropToolView)
        }
        if config.fixedCropState {
            pState = .cropping
            editorToolView.alpha = 0
            editorToolView.isHidden = true
            topView.alpha = 0
            topView.isHidden = true
        }else {
            pState = config.state
            if toolOptions.contains(.graffiti) {
                view.addSubview(brushColorView)
                view.addSubview(brushBlockView)
            }
            if toolOptions.contains(.chartlet) {
                view.addSubview(chartletView)
            }
            if toolOptions.contains(.mosaic) {
                view.addSubview(mosaicToolView)
            }
            if toolOptions.contains(.filter) {
                view.addSubview(filterView)
                view.addSubview(filterParameterView)
            }
        }
        view.layer.addSublayer(topMaskLayer)
        view.addSubview(topView)
        //        editorToolView.backgroundColor = .darkGray
        //        topView.backgroundColor = .cyan
        if needRequest {
            if requestType == 1 {
                //                #if HXPICKER_ENABLE_PICKER
                requestImage()
                //                #endif
            }else if requestType == 2 {
#if canImport(Kingfisher)
                requestNetworkImage()
#endif
            }
        }else {
            if !config.fixedCropState {
                localImageHandler()
            }
        }
        initView()
    }
    open override func deviceOrientationWillChanged(notify: Notification) {
        orientationDidChange = true
        imageViewDidChange = false
        
        if let type = currentToolOption?.type,
           type == .chartlet {
            singleTap()
        }
        imageView.undoAllDraw()
        if toolOptions.contains(.graffiti) {
            brushColorView.canUndo = imageView.canUndoDraw
        }
        imageView.undoAllMosaic()
        if toolOptions.contains(.mosaic) {
            mosaicToolView.canUndo = imageView.canUndoMosaic
        }
        imageView.undoAllSticker()
        imageView.reset(false)
        imageView.finishCropping(false)
        imageView.imageResizerView.isDidFinishedClick = false
        cropToolView.resetSelected()
        if config.fixedCropState {
            return
        }
        pState = .normal
        croppingAction()
    }
    open override func deviceOrientationDidChanged(notify: Notification) {
        //        orientationDidChange = true
        //        imageViewDidChange = false
    }
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        editorToolView.frame = CGRect(
            x: cancelBtn.frame.width,
            y: 0,
            width: view.width,
            height: 44
        )
        editorToolView.reloadContentInset()
        topView.y = 0
        topView.width = view.width
        topView.height = UIDevice.isPortrait ? 44 : 32
        cancelBtn.height = topView.height
        cancelBtn.x = UIDevice.leftMargin
        let viewControllersCount = navigationController?.viewControllers.count ?? 0
        if let modalPresentationStyle = navigationController?.modalPresentationStyle,
           UIDevice.isPortrait {
            if (modalPresentationStyle == .fullScreen ||
                modalPresentationStyle == .custom ||
                viewControllersCount > 1) &&
                modalPresentationStyle != .pageSheet {
                topView.y = UIDevice.generalStatusBarHeight
            }
        }else if (
            modalPresentationStyle == .fullScreen ||
            modalPresentationStyle == .custom ||
            viewControllersCount > 1
        ) && UIDevice.isPortrait && modalPresentationStyle != .pageSheet {
            topView.y = UIDevice.generalStatusBarHeight
        }
        topMaskLayer.frame = CGRect(x: 0, y: 0, width: view.width, height: topView.frame.maxY + 10)
        
        let cropToolFrame = CGRect(x: 0, y: editorToolView.y + 72, width: view.width, height: 60)
        
        let cropConfirmViewFrame = CGRect(x: 0, y: view.height - 72, width: view.width, height: 60)
        
        //        cropConfirmView.backgroundColor = .blue
        if toolOptions.contains(.cropSize) {
            cropConfirmView.frame = cropConfirmViewFrame //editorToolView.frame
            cropToolView.frame = cropToolFrame
            cropToolView.updateContentInset()
        }
        if toolOptions.contains(.graffiti) {
            brushColorView.frame = CGRect(x: 0, y: editorToolView.y + 72, width: view.width, height: 65)
            brushBlockView.x = view.width - 45 - UIDevice.rightMargin
            if UIDevice.isPortrait {
                brushBlockView.centerY = view.height * 0.5
            }else {
                brushBlockView.y = brushColorView.y - brushBlockView.height
            }
        }
        if toolOptions.contains(.mosaic) {
            mosaicToolView.frame = cropToolFrame
        }
        if toolOptions.isSticker {
            setChartletViewFrame()
        }
        if toolOptions.contains(.filter) {
            setFilterViewFrame()
            setFilterParameterViewFrame()
        }
        if !imageView.frame.equalTo(view.bounds) && !imageView.frame.isEmpty && !imageViewDidChange {
            imageView.frame = view.bounds
            imageView.reset(false)
            imageView.finishCropping(false)
            imageView.imageResizerView.isDidFinishedClick = false
            cropToolView.resetSelected()
            orientationDidChange = true
        }else {
            imageView.frame = view.bounds
        }
        if !imageInitializeCompletion {
            if !needRequest || image != nil {
                imageView.setImage(image)
                //                setFilterImage()
                if let editedData = editResult?.editedData {
                    imageView.setEditedData(editedData: editedData)
                    if toolOptions.contains(.graffiti) {
                        brushColorView.canUndo = imageView.canUndoDraw
                    }
                    if toolOptions.contains(.mosaic) {
                        mosaicToolView.canUndo = imageView.canUndoMosaic
                    }
                }
                imageInitializeCompletion = true
                if transitionCompletion {
                    initializeStartCropping()
                }
            }
        }
        if orientationDidChange {
            imageView.orientationDidChange()
            if config.fixedCropState {
                imageView.startCropping(false)
            }
            orientationDidChange = false
            imageViewDidChange = true
        }
        didLayoutBottomSubviews()
        updateFinishButtonFrame()
    }
    func didLayoutBottomSubviews(){
        let margin: CGFloat = 8
        let itemWidth = 40 + margin
        let cvSize = CGSize(width: 40, height: 48)
        collectionViewLayout.minimumLineSpacing = margin
        collectionViewLayout.itemSize = cvSize
        let contentWidth = (view.width + itemWidth) * CGFloat(assetCount)
        
        bottomBGV.frame = CGRect(x: 0, y: view.height - cvSize.height - UIDevice.bottomMargin - margin, width: view.width, height: cvSize.height)
        
        
        collectionView.frame = CGRect(x: 0, y: 0 , width: bottomBGV.width, height: bottomBGV.height)
        
        collectionView.contentSize = CGSize(width: contentWidth, height: view.height)
        collectionView.setContentOffset(CGPoint(x: CGFloat(currentPreviewIndex) * itemWidth, y: 0), animated: false)
        
        
        
//        DispatchQueue.main.async {
//            if self.orientationDidChange {
//                let cell = self.getCell(for: self.currentPreviewIndex)
//                cell?.setupScrollViewContentSize()
//                self.orientationDidChange = false
//            }
//        }
        configBottomViewFrame()
//        if firstLayoutSubviews {
//            guard let photoAsset = photoAsset(for: currentPreviewIndex) else {
//                return
//            }
//            if configPreview.bottomView.showSelectedView &&
//                (isMultipleSelect || isExternalPreview) && configPreview.showBottomView {
//                DispatchQueue.main.async {
//                    //                    self.bottomView.selectedView.scrollTo(
//                    //                        photoAsset: photoAsset,
//                    //                        isAnimated: false
//                    //                    )
//                }
//            }
//            firstLayoutSubviews = false
//        }
    }
    private func configureBottomBGV(){
        bottomBGV = UIView()
        bottomBGV.addSubview(collectionView)
        bottomBGV.addSubview(finishBtn)
        self.view.addSubview(bottomBGV)
        configButtonColor()
        //        self.bottomBGV.backgroundColor = .brown
    }
    private func initView() {
        configColor()
        
        configureBottomBGV()
        //        view.addSubview(collectionView)
        // bottomBGV.addSubview(collectionView)
        //        if configPreview.showBottomView {
        //            view.addSubview(bottomView)
        //            bottomView.updateFinishButtonTitle()
        //        }
//        if let pickerController = pickerController, (isExternalPreview || isExternalPickerPreview) {
//            //            statusBarShouldBeHidden = pickerController.config.prefersStatusBarHidden
//            if pickerController.modalPresentationStyle != .custom {
//                configColor()
//            }
//        }
//        if isMultipleSelect || isExternalPreview {
//            videoLoadSingleCell = pickerController!.singleVideo
//            if !isExternalPreview {
//                if isExternalPickerPreview {
//                    //                    let cancelItem = UIBarButtonItem(
//                    //                        image: "hx_picker_photolist_cancel".image,
//                    //                        style: .done,
//                    //                        target: self,
//                    //                        action: #selector(didCancelItemClick)
//                    //                    )
//                    //                    navigationItem.leftBarButtonItem = cancelItem
//                }
//
//            }else {
//                var cancelItem: UIBarButtonItem
//                if configPreview.cancelType == .image {
//                    let isDark = PhotoManager.isDark
//                    //                    cancelItem = UIBarButtonItem(
//                    //                        image: UIImage.image(
//                    //                            for: isDark ? configPreview.cancelDarkImageName : configPreview.cancelImageName
//                    //                        ),
//                    //                        style: .done,
//                    //                        target: self,
//                    //                        action: #selector(didCancelniItemClick)
//                    //                    )
//                }else {
//                    //                    cancelItem = UIBarButtonItem(
//                    //                        title: "Cancel".localized,
//                    //                        style: .done,
//                    //                        target: self,
//                    //                        action: #selector(didCancelItemClick)
//                    //                    )
//                }
//                //                if configPreview.cancelPosition == .left {
//                //                    navigationItem.leftBarButtonItem = cancelItem
//                //                } else {
//                //                    navigationItem.rightBarButtonItem = cancelItem
//                //                }
//            }
//            if assetCount > 0 && currentPreviewIndex == 0 {
//                if let photoAsset = photoAsset(for: 0) {
//                    if configPreview.bottomView.showSelectedView && configPreview.showBottomView {
//                        //                        bottomView.selectedView.scrollTo(photoAsset: photoAsset)
//                    }
//                    if !isExternalPreview {
//                        if photoAsset.mediaType == .video && videoLoadSingleCell {
//                            // selectBoxControl.isHidden = true
//                        } else {
//                            //                            updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
//                            //                            selectBoxControl.isSelected = photoAsset.isSelected
//                        }
//                    }
//                    //                    #if HXPICKER_ENABLE_EDITOR
//                    if let pickerController = pickerController, !configPreview.bottomView.editButtonHidden,
//                       configPreview.showBottomView {
//                        if photoAsset.mediaType == .photo {
//                            //                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.isPhoto
//                        }else if photoAsset.mediaType == .video {
//                            //                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.contains(.video)
//                        }
//                    }
//                    //                    #endif
//                    pickerController?.previewUpdateCurrentlyDisplayedAsset(
//                        photoAsset: photoAsset,
//                        index: currentPreviewIndex
//                    )
//                }
//            }
//        }else if !isMultipleSelect {
//            if isExternalPickerPreview {
//                //                let cancelItem = UIBarButtonItem(
//                //                    image: "hx_picker_photolist_cancel".image,
//                //                    style: .done,
//                //                    target: self,
//                //                    action: #selector(didCancelItemClick)
//                //                )
//                //                navigationItem.leftBarButtonItem = cancelItem
//            }
//            if assetCount > 0 && currentPreviewIndex == 0 {
//                if let photoAsset = photoAsset(for: 0) {
//                    //                    #if HXPICKER_ENABLE_EDITOR
//                    if let pickerController = pickerController, !configPreview.bottomView.editButtonHidden,
//                       configPreview.showBottomView {
//                        if photoAsset.mediaType == .photo {
//                            //                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.isPhoto
//                        }else if photoAsset.mediaType == .video {
//                            //                            bottomView.editBtn.isEnabled = pickerController.config.editorOptions.contains(.video)
//                        }
//                    }
//                    //                    #endif
//                    pickerController?.previewUpdateCurrentlyDisplayedAsset(
//                        photoAsset: photoAsset,
//                        index: currentPreviewIndex
//                    )
//                }
//            }
//        }
    }
    func configColor() {
        view.backgroundColor = PhotoManager.isDark ?
        configPreview.backgroundDarkColor :
        configPreview.backgroundColor
    }
    func configBottomViewFrame() {
        //        if !configPreview.showBottomView {
        //            return
        //        }
        //        var bottomHeight: CGFloat = 0
        //        if isExternalPreview {
        //            bottomHeight = (pickerController?.selectedAssetArray.isEmpty ?? true) ? 0 : UIDevice.bottomMargin + 70
        ////            #if HXPICKER_ENABLE_EDITOR
        //            if !configPreview.bottomView.showSelectedView && configPreview.bottomView.editButtonHidden {
        //                if configPreview.bottomView.editButtonHidden {
        //                    bottomHeight = 0
        //                }else {
        //                    bottomHeight = UIDevice.bottomMargin + 50
        //                }
        //            }
        //            #endif
        //        }else {
        //            if let picker = pickerController {
        //                bottomHeight = picker.selectedAssetArray.isEmpty ?
        //                    50 + UIDevice.bottomMargin : 50 + UIDevice.bottomMargin + 70
        //            }
        //            if !configPreview.bottomView.showSelectedView || !isMultipleSelect {
        //                bottomHeight = 50 + UIDevice.bottomMargin
        //            }
        //        }
        //        bottomView.frame = CGRect(
        //            x: 0,
        //            y: view.height - bottomHeight,
        //            width: view.width,
        //            height: bottomHeight
        //        )
    }
    
    func initializeStartCropping() {
        if !imageInitializeCompletion || state != .cropping {
            return
        }
        imageView.startCropping(true)
        croppingAction()
    }
    func setChartletViewFrame() {
        var viewHeight = config.chartlet.viewHeight
        if viewHeight > view.height {
            viewHeight = view.height * 0.6
        }
        if let type = currentToolOption?.type,
           type == .chartlet {
            chartletView.frame = CGRect(
                x: 0,
                y: view.height - viewHeight - UIDevice.bottomMargin,
                width: view.width,
                height: viewHeight + UIDevice.bottomMargin
            )
        }else {
            chartletView.frame = CGRect(
                x: 0,
                y: view.height,
                width: view.width,
                height: viewHeight + UIDevice.bottomMargin
            )
        }
    }
    func setFilterViewFrame() {
        let filterHeight: CGFloat
#if canImport(Harbeth)
        filterHeight = 155 + UIDevice.bottomMargin
#else
        filterHeight = 125 + UIDevice.bottomMargin
#endif
        if let type = currentToolOption?.type,
           type == .filter {
            filterView.frame = CGRect(
                x: 0,
                y: view.height - filterHeight,
                width: view.width,
                height: filterHeight
            )
        }else {
            filterView.frame = CGRect(
                x: 0,
                y: view.height + 10,
                width: view.width,
                height: filterHeight
            )
        }
    }
    func setFilterParameterViewFrame() {
        let editHeight = max(CGFloat(filterParameterView.models.count) * 40 + 30 + UIDevice.bottomMargin, filterView.height)
        if isShowFilterParameter {
            filterParameterView.frame = .init(
                x: 0,
                y: view.height - editHeight,
                width: view.width,
                height: editHeight
            )
        }else {
            filterParameterView.frame = .init(
                x: 0,
                y: view.height,
                width: view.width,
                height: editHeight
            )
        }
    }
    open override var prefersStatusBarHidden: Bool {
        return config.prefersStatusBarHidden
    }
    open override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .all
    }
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.topViewController != self &&
            navigationController?.viewControllers.contains(self) == false {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.viewControllers.count == 1 {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }else {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let isHidden = navigationController?.navigationBar.isHidden, !isHidden {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    
    func setImage(_ image: UIImage) {
        self.image = image
    }
    
    func photoAsset(for index: Int) -> PhotoAsset? {
        if !previewAssets.isEmpty && index > 0 || index < previewAssets.count {
            return previewAssets[index]
        }
        return assetForIndex?(index)
    }
    
    func getCell(for item: Int) -> PhotoPreviewViewCell? {
        if assetCount == 0 {
            return nil
        }
        let cell = collectionView.cellForItem(
            at: IndexPath(
                item: item,
                section: 0
            )
        ) as? PhotoPreviewViewCell
        return cell
    }
    
    func getEditorCell(for item: Int) -> PhotoEditorPreviewCell? {
        if assetCount == 0 {
            return nil
        }
        let cell = collectionView.cellForItem(
            at: IndexPath(
                item: item,
                section: 0
            )
        ) as? PhotoEditorPreviewCell
        return cell
    }

}
