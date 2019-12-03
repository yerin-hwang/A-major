IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Detects keypoints and computes SURF (Speeded-Up Robust Features) descriptors on the webcam interface."

ProcedureC WindowCallback(hWnd, Msg, wParam, lParam)
  Shared exitCV.b

  Select Msg
    Case #WM_COMMAND
      Select wParam
        Case 10
          exitCV = #True
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, Msg, wParam, lParam)
EndProcedure

ProcedureC CvMouseCallback(event, x.l, y.l, flags, *param.USER_INFO)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\uValue)
  EndSelect
EndProcedure

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(#CV_CAP_ANY)
Until nCreate = 5 Or *capture

If *capture
  nonfree2411 = OpenLibrary(#PB_Any, "opencv_nonfree2411.dll")
  cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
  window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
  *window_name = cvGetWindowName(window_handle)
  lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

  If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
    MenuItem(10, "Exit")
  EndIf
  hWnd = GetParent_(window_handle)
  opencv = LoadImage_(GetModuleHandle_(0), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
  SendMessage_(hWnd, #WM_SETICON, 0, opencv)
  wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
  SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)
  *gray.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *keypoints.CvSeq
  *descriptors.CvSeq
  *storage.CvMemStorage = cvCreateMemStorage(0)
  cvClearMemStorage(*storage)
  *element.CvSURFPoint
  *image.IplImage
  *param.USER_INFO = AllocateMemory(SizeOf(USER_INFO))
  *param\uValue = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvCvtColor(*image, *gray, #CV_BGR2GRAY, 1)
      cvExtractSURF(*gray, #Null, @*keypoints, @*descriptors, *storage, 0, 0, 500, 4, 2, #False)

      For rtnCount = 0 To *keypoints\total - 1
        *element = cvGetSeqElem(*keypoints, rtnCount)
        x = Round(*element\pt\x, #PB_Round_Nearest)
        y = Round(*element\pt\y, #PB_Round_Nearest)
        radius = Round(*element\size * 1.2 / 9 * 2, #PB_Round_Nearest)
        cvCircle(*image, x, y, radius, 0, 0, 255, 0, 1, #CV_AA, #Null)
      Next
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(100)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMemStorage(@*storage)
  cvReleaseImage(@*gray)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
  CloseLibrary(nonfree2411)
EndIf
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\