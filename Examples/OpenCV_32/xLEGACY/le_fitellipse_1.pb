IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV.b, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Creates a sequence of points, bounding them in an ellipse of the minimal area."

ProcedureC WindowCallback(hWnd, Msg, wParam, lParam)
  Select Msg
    Case #WM_COMMAND
      Select wParam
        Case 1
          FileName.s = SaveFile()

          If FileName
            params.SAVE_INFO

            Select LCase(GetExtensionPart(FileName))
              Case "jpeg", "jpg", "jpe"
                params\paramId = #CV_IMWRITE_JPEG_QUALITY
                params\paramValue = 95
              Case "png"
                params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                params\paramValue = 3
              Case "ppm", "pgm", "pbm"
                params\paramId = #CV_IMWRITE_PXM_BINARY
                params\paramValue = 1
              Default
                Select SelectedFilePattern()
                  Case 0
                    FileName + ".jpg"
                    params\paramId = #CV_IMWRITE_JPEG_QUALITY
                    params\paramValue = 95
                  Case 1
                    FileName + ".png"
                    params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                    params\paramValue = 3
                  Case 2
                    FileName + ".ppm"
                    params\paramId = #CV_IMWRITE_PXM_BINARY
                    params\paramValue = 1
                EndSelect
            EndSelect
            cvSaveImage(FileName, *save, @params)
          EndIf
        Case 10
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, Msg, wParam, lParam)
EndProcedure

ProcedureC CvMouseCallback(event, x.l, y.l, flags, *param.USER_INFO)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\uPointer1
      DisplayPopupMenu(0, *param\uValue)
  EndSelect
EndProcedure

cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
*window_name = cvGetWindowName(window_handle)
lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
  MenuItem(1, "Save")
  MenuBar()
  MenuItem(10, "Exit")
EndIf
hWnd = GetParent_(window_handle)
opencv = LoadImage_(GetModuleHandle_(0), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
SendMessage_(hWnd, #WM_SETICON, 0, opencv)
wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
*image.IplImage = cvCreateImage(600, 400, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
cvSetZero(*image)
#CV_SEQ_ELTYPE_POINT = CV_MAKETYPE(#CV_32S, 2)
*storage.CvMemStorage = cvCreateMemStorage(0)
cvClearMemStorage(*storage)
*sequence.CvSeq = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *storage)
element.CvPoint

For y = 120 To 270 Step 25
  For x = 70 To 190 Step 25
    offset + 10
    element\x = x + offset
    element\y = y
    cvSeqPush(*sequence, @element)
    cvCircle(*image, element\x, element\y, 2, 100, x - 150, y, 0, 3, #CV_AA, #Null)
  Next
Next
Dim pts1.CvPoint(*sequence\total)
Dim pts2.CvPoint2D32f(*sequence\total)
cvCvtSeqToArray(*sequence, @pts1(), 0, #CV_WHOLE_SEQ_END_INDEX)

For rtnPoint = 0 To *sequence\total - 1
  pts2(rtnPoint)\x = pts1(rtnPoint)\x
  pts2(rtnPoint)\y = pts1(rtnPoint)\y
Next
box.CvBox2D
cvFitEllipse(pts2(), *sequence\total, @box)
cvEllipse(*image, box\center\x, box\center\y, box\size\width * 0.65, box\size\height * 0.65, box\angle, 0, 360, 0, 255, 255, 0, 1, #CV_AA, #Null)
angle.d = 45 + box\angle
font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, #Null, 1, #CV_AA)
cvPutText(*image, Str(angle) + " Degrees", 20, 360, @font, 255, 200, 100, 0)
*param.USER_INFO = AllocateMemory(SizeOf(USER_INFO))
*param\uPointer1 = *image
*param\uValue = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseMemStorage(@*storage)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\