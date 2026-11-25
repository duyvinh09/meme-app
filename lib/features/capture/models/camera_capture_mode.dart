enum CameraCaptureMode {
  photo,
  bill,
  video;

  bool get allowsPhotobooth => this == CameraCaptureMode.photo;
  bool get allowsGallery => this != CameraCaptureMode.bill;
}
