﻿;IncludeFile "includes/cv_functions.pbi"
;-- 0428~0429 채점기능, 입력값 뽑아내기
;-- 0427 박자 넣어서 재생하기! 박자 별로 딜레이 다르게 줌
;-- 0426 스레드 안쓰고 해결...v1. 화음도 그려줌 (애니메이션은 x), v2. 박자......정보 수정하기................
;-- 0425 스레드로 재생하기 시도
;-- 0421 소리 재생 o, 스프라이트 재생 x (PlayAll 함수 내에서 프레임 전환x)
;-- 0420~0421 재생모드 작업 중
;-- 0418~0419 코드 입력 <-> 수정 가능 (showCurrentBar에러해결해야 함..)
;-- 0417 코드 수정모드 작업 중
;-- 0416 멜로디 수정모드 에러 고침! 전체 멜로디 입력 완료 후 수정가능, 전체 멜로디 입력 완료하기 전에도 수정 가능, 마디 이동하며 원하는 마디 수정 가능!

; [KEYBOARD] 1: green tracking, 2: red tracking, spacebar: state change
; 처음 시작 후, 마우스 커서와 키보드 1(혹은 2)로 박스 영역 설정 -> 스페이스바로 상태 전환 -> 마우스 커서와 키보드 1(혹은 2)로 음 출력
; 키보드3 : 멜로디 입력 <-> 코드 입력 전환 (기본 상태는 멜로디 입력, 처음 누르면 코드 입력으로 전환)
; 키보드4 : 입력 <-> 수정 전환 (기본 상태는 입력, 처음 누르면 수정모드로 전환)
  
Structure mySprite_lv3
  sprite_id.i
  sprite_name.s
  filename.s
  
  num.i ; 몇 번 음(또는 화음)인지 저장
  beat_lv3.i ; 음표 스프라이트만 박자 저장
  
  x.i   ; 위치 x
  y.i   ; 위치 y
  width.i   ; 전체 가로 사이즈
  height.i  ; 전체 세로 사이즈
  
  present.i; 현재 프레임
  frametime.i
  
  f_width.i ; 한 프레임의 가로 사이즈
  f_height.i; 한 프레임의 세로 사이즈
  f_horizontal.i   ; 가로 프레임 수
  f_vertical.i     ; 세로 프레임 수
  
  active.i  ; 0(invisible)or 1(visible)
  
EndStructure


;-Structure Bar_lv3
Structure Bar_lv3
  List note_lv3.mySprite_lv3()
  List chord.mySprite_lv3()
EndStructure


Structure myPosition_lv3
  *sprite.mySprite_lv3
  xmove.i
  ymove.i
  xmax.i
  ymax.i
  startdelay.i
  frametime.i
EndStructure

Enumeration Chordes ;--2단계 코드에서 순서 바꿈!!
  #CHORD_C = 1 ;1부터 시작, 1도 화음
  #CHORD_Dm
  #CHORD_Em
  #CHORD_F
  #CHORD_G
  #CHORD_Am
  
EndEnumeration

Structure Problem_lv3
  note1.i
  note2.i
  answer.i
EndStructure

;-- 전역변수 선언

Global keyInput, inputTone, answerTone, currentTime, direction, inputCount = -1
Global intervalStart = 0, intervalEnd = 0, dist_lv3, beat_lv3, beatSum_lv3 = 0 ;박자 측정하기 위한 변수
Global Dim ptBox.CvPoint(7, 4)
Global NewList sprite_list_lv3.mySprite_lv3()
Global Dim bar_list_lv3.Bar_lv3(3)
Global NewList position_list_lv3.myPosition_lv3()
Global complete = 0 ;입력완료 flag
Global x_lv3 = 800
Global barCount = 0, currentBar.i ;마디 수 측정
Global inputMode = 0              ;입력모드(화음 or 음 입력)
Global editMode = 0               ;편집모드
Global Dim note_lv3(2)
Global chordCount = 0
Global check = 0
Global Dim score(7)

Global Dim keyColor.color(6)


Procedure DrawMySprite_lv3(*this.mySprite_lv3)
  If *this\active = 1
    ; 일반 스프라이트
    DisplayTransparentSprite(*this\sprite_id, *this\x, *this\y)
  EndIf
  
EndProcedure

;이미지 프레임 넘기는 함수
Procedure FrameManager_lv3(*this.mySprite_lv3)
  If *this\active = 1 And *this\f_horizontal > 1
    If *this\present = -1
      *this\frameTime = currentTime + 100
      *this\present = 0
      ClipSprite(*this\sprite_id, *this\present * *this\f_width, 0, *this\f_width, *this\f_height)
      *this\present = 1
    EndIf
    
    If *this\frameTime <= currentTime
      ClipSprite(*this\sprite_id, *this\present * *this\f_width, 0, *this\f_width, *this\f_height)
      *this\frameTime = currentTime + 100
      If *this\present = *this\f_horizontal - 1
        *this\present = 0
      Else
        *this\present = *this\present + 1
      EndIf
      
    EndIf 
  EndIf
EndProcedure

Procedure InitMySprite_lv3(name.s, filename.s, x.i, y.i, type.i, active.i = 1) ;active는 옵션
                                                                   ; 스프라이트 구조체 초기화
  CreateSprite(#PB_Any, width, height)
  mysprite = LoadSprite(#PB_Any, filename.s)
  
  If type = 0 ;일반 스프라이트
    *newsprite.mySprite_lv3 = AddElement(sprite_list_lv3())
  ElseIf type = 1 ;음표(과일) 스프라이트
    *newsprite.mySprite_lv3 = AddElement(bar_list_lv3(currentBar)\note_lv3())   ;beat_lv3, bar 따로 저장
  ElseIf type = 2 ;화음 스프라이트
    *newsprite.mySprite_lv3 = AddElement(bar_list_lv3(currentBar)\chord())
  EndIf  
  
  
  *newsprite\num = -1 
  *newsprite\beat_lv3 = -1  ;일반 스프라이트
    
  *newsprite\sprite_id = mysprite
  *newsprite\sprite_name = name
  *newsprite\filename = filename
  
  *newsprite\width = SpriteWidth(mysprite)
  *newsprite\height = SpriteHeight(mysprite)
  
  *newsprite\f_width = SpriteWidth(mysprite)
  *newsprite\f_height = SpriteHeight(mysprite)
  *newsprite\present = -1 ; TODO
  
  *newsprite\x = x
  *newsprite\y = y
  
  *newsprite\f_horizontal = Int(width/f_width)
  *newsprite\f_vertical = Int(height/f_height)
  
  *newsprite\active = active  ; default : visible
  
EndProcedure

;스프라이트 좌표값, 활성화여부 변경
Procedure SetMySprite_lv3(*sprite.mySprite_lv3, x.i, y.i, active.i)
  *sprite\x = x
  *sprite\y = y
  *sprite\active = active
EndProcedure

;myPosition_lv3 초기화
Procedure InitMyPosition_lv3(*sprite.mySprite_lv3, xmove.i, ymove.i, xmax.i, ymax.i, startdelay.i)
  *this.myPosition_lv3 = AddElement(position_list_lv3())
  
  *this\sprite = *sprite
  *this\xmove = xmove
  *this\ymove = ymove
  *this\xmax = xmax
  *this\ymax = ymax
  *this\startdelay = startdelay
EndProcedure

; sprite_list_lv3 에서 이름으로 구조체 찾기. 퓨베 특성상 current element 이슈 때문에 도중에 일치해도 끝까지 루프를 돌아야함
Procedure FindSprite_lv3(name.s)
  *returnStructure.mySprite_lv3
  
  ForEach sprite_list_lv3()
    If sprite_list_lv3()\sprite_name = name
      returnStructrue = sprite_list_lv3()
    EndIf 
  Next
  
  ProcedureReturn returnStructrue
EndProcedure

; 좌표값 옮겨주는 함수
Procedure ChangePos_lv3(*this.myPosition_lv3)
  If *this\startdelay > 0
    *this\startdelay = *this\startdelay - 1
    ProcedureReturn
  ElseIf  *this\startdelay = 0
    *this\frameTime = GetTickCount_() + 100 
    *this\startdelay = -1
  ElseIf  *this\startdelay = -1     
    If *this\frameTime <= currentTime
      *this\sprite\x = *this\sprite\x + *this\xmove
      *this\sprite\y = *this\sprite\y + *this\ymove
      *this\frameTime = currentTime + 50
    EndIf 
  EndIf
  
  
  If *this\sprite\x = *this\xmax Or *this\sprite\y = *this\ymax  
    DeleteElement(position_list_lv3())
  EndIf 
  
  
EndProcedure




Procedure MoveAnt_Lv3()
  Repeat
    currentTime = GetTickCount_()
    ForEach position_list_lv3()
      ChangePos_lv3(position_list_lv3())
    Next
    
    currentTime = GetTickCount_()
    ;For i=0 To 3 
    ForEach bar_list_lv3(currentBar)\note_lv3()
      FrameManager_lv3(bar_list_lv3(currentBar)\note_lv3())
    Next
    
    currentTime = GetTickCount_()
    ForEach bar_list_lv3(currentBar)\chord()
      FrameManager_lv3(bar_list_lv3(currentBar)\chord())
    Next
    ;Next
    
    currentTime = GetTickCount_()
    ForEach sprite_list_lv3()
      FrameManager_lv3(sprite_list_lv3()) ;active 상태인 것들만 다음 프레임으로
    Next

    
    ForEach sprite_list_lv3()
      DrawMySprite_lv3(sprite_list_lv3())
    Next
    
    ;For i=0 To 3 
    ForEach bar_list_lv3(currentBar)\note_lv3()
      DrawMySprite_lv3(bar_list_lv3(currentBar)\note_lv3())
    Next
    
    ForEach bar_list_lv3(currentBar)\chord()
      DrawMySprite_lv3(bar_list_lv3(currentBar)\chord())
    Next
    ;Next
    
    FlipBuffers()
  Until ListSize(position_list_lv3()) = 0
  
EndProcedure

;음 길이 계산하는 함수, 여기서 음 길이는 현재 입력 음이 아닌 바로 앞의 음에 해당(음 두 개의 간격으로 계산하므로)
Procedure CalcBeat_lv3()
  
  interval = intervalStart - intervalEnd ;현재 음 입력시간 - 이전 음 입력시간
  
 ; Debug Interval
  
  If Interval >=1000 And Interval <5000
    dist_lv3 = 160
    beat_lv3 = 600 ;두 박자(2분 음표), x좌표 간격 160으로 
  ElseIf Interval >=500 And Interval <1000
    dist_lv3 = 80
    beat_lv3 = 450  ;한 박자(4분 음표), x좌표 간격 80으로 
  ElseIf Interval < 500
    dist_lv3 = 40
    beat_lv3 = 300  ;반 박자(8분 음표), x좌표 간격 40으로
  ElseIf Interval >= 5000
    dist_lv3 = 0
    beat_lv3 = 0  ;간격이 매우 크다 -> 맨 처음 입력한 음 
  EndIf
  
  ;Debug beat_lv3
  
  ; 총 몇 박자인지 파악 (4박자 채우면 마디 넘김)
  beatSum_lv3 = beatSum_lv3 + dist_lv3
  ;Debug beatSum_lv3
  
EndProcedure


;입력한 음을 기억했다가 마디 이동시에 다시 그려주는 함수
Procedure DrawNote_lv3(b)
  
  ; 전체 음 다 지우기
  For i=0 To 3 
    ForEach bar_list_lv3(i)\note_lv3()
      bar_list_lv3(i)\note_lv3()\active = 0
    Next
    
    ForEach bar_list_lv3(i)\chord()
      bar_list_lv3(i)\chord()\active = 0
    Next

  Next
  
  Debug "b" + Str(b)
  ; 현재 화면의 음만 그려주기
  ForEach bar_list_lv3(b)\note_lv3()
    bar_list_lv3(b)\note_lv3()\active= 1
  Next
  
  
  ForEach bar_list_lv3(b)\chord()
    bar_list_lv3(b)\chord()\active= 1
  Next
  

  
EndProcedure


Procedure showCurrentBar_lv3()
  
   x.i
   Select chordCount ;-- 여기..코드 카운트로 케이스 나눠서 edit모드에서 문제....
    Case 0
      x = 50
    Case 1
      x = 165
    Case 2
      x = 280
    Case 3
      x = 395
    Case 4
      x = 510
    Case 5
      x = 625
    Case 6
      x = 740
    Case 7
      x = 855
  EndSelect
  
  
  
  ;Debug "코드번호" + Str(bar_list_lv3(currentBar)\chord()\num)

  InitMySprite_lv3("Bar" + Str(chordCount), "graphics/graphics_lv3/"+Str(bar_list_lv3(currentBar)\chord()\num) + ".png", x, 10, 0, 1)
  ;*p\filename = "graphics/graphics_lv3/" + Str(bar_list_lv3(currentBar)\chord()\num)
  
EndProcedure


;음 입력하면 과일 그려주는 함수
Procedure AddNote_lv3()
  
  CalcBeat_lv3()
  
  y = 160
  xx = x_lv3
  x_lv3 = xx + dist_lv3
  
    ;수정모드
  If editMode = 1 And inputCount = -1
    ClearList(bar_list_lv3(currentBar)\note_lv3())  
    x_lv3 = 800
    barCount = currentBar
    beatSum_lv3 = 0
  EndIf
 
  ;현재 화면 밖으로 벗어나는 경우
  If x_lv3 > 1440
  ;If beatSum_lv3 = 8  
    barCount = barCount + 1 ; 여기가 문제!!!!!!!!
    
    ;마디 수 체크
    If barCount > 3 And editMode = 0
      Debug "입력 끝"
      complete = 1
      barCount = 3
      ;--맨 마지막 음 박자 계산! 나중에는 마지막 마디 입력 끝나면 저장하는걸로 바꾸기!!
      *p.mySprite_lv3 = LastElement(bar_list_lv3(3)\note_lv3())
      diff = 1480 - *p\x
      If diff = 160
        *p\beat_lv3 = 600 ;두박자
      ElseIf diff = 80
        *p\beat_lv3 = 450 ;한박자
      ElseIf diff = 40
        *p\beat_lv3 = 300 ;반박자
      EndIf
      ;inputCount = -1
    
    ElseIf editMode = 1
      ;inputCount = -1
      editMode = 0
      Debug "에딧모드 종료"
      If complete = 1
        barCount = 3
      Else
        barCount = barCount - 1
      EndIf
      
    Else
      ;화면 전환, 앞에 그린 음 지우기
      For i=0 To 3 
        ForEach bar_list_lv3(i)\note_lv3()
          bar_list_lv3(i)\note_lv3()\active = 0
        Next
      Next
      
      ;Debug "화면 전환"
      currentBar = barCount
      
      *b.mySprite_lv3 = FindSprite_lv3("background")
      *b\active = 0
      
      *b.mySprite_lv3 = FindSprite_lv3("background2")
      *b\active = 1
      
      ;숫자 마디 (비)활성화 
      For i=1 To 8
        *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i)+"_a")
        *p\active = 0
      Next
      
      *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+1)+"_a")
      *p\active = 1
      
      
      x_lv3 = 800 ;초기화, 첫 위치부터 다시 그림
      InitMySprite_lv3("note"+Str(inputTone+1), "graphics/graphics_lv3/lines"+Str(inputTone+1)+".png", x_lv3, y, 1, 1)
      bar_list_lv3(currentBar)\note_lv3()\num = inputTone+1
      *p.mySprite_lv3 = LastElement(bar_list_lv3(currentBar-1)\note_lv3())
      diff = 1480 - *p\x
      If diff = 160
        *p\beat_lv3 = 600 ;두박자
      ElseIf diff = 80
        *p\beat_lv3 = 450 ;한박자
      ElseIf diff = 40
        *p\beat_lv3 =300 ;반박자
      EndIf
      
      ;Debug "currentBar" + Str(currentBar)
      ;Debug "이전 음 beat_lv3" + Str(*p\beat_lv3) + "이전 음 x" + Str(*p\x)
      ;Debug "이전 음 x" + Str(*p\x)
      ;bar_list_lv3(currentBar)\note_lv3()\beat_lv3 = beat_lv3

     
      beatSum_lv3 = 0
    EndIf
    
  ;화면상에서 두번째 마디 시작
  ElseIf beatSum_lv3 = 320
   
    currentBar = barCount
    
    ;숫자 마디 (비)활성화 
    For i=1 To 8
      *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i)+"_a")
      *p\active = 0
    Next
    
    *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+2)+"_a")
    *p\active = 1
    
    
    
    x_lv3 = 1160 ;두번째 마디 시작점
    
    InitMySprite_lv3("note"+Str(inputTone+1), "graphics/graphics_lv3/lines"+Str(inputTone+1)+".png", x_lv3, y, 1, 1)
    bar_list_lv3(currentBar)\note_lv3()\num = inputTone+1
    ;bar_list_lv3(currentBar)\note_lv3()\beat_lv3 = beat_lv3
    *p.mySprite_lv3 = PreviousElement(bar_list_lv3(currentBar)\note_lv3())
    diff = 1160 - *p\x
    If diff = 200
      *p\beat_lv3 = 600 ;두박자
    ElseIf diff = 120
      *p\beat_lv3 = 450 ;한박자
    ElseIf diff = 80
      *p\beat_lv3 = 300 ;반박자
    EndIf
    ;Debug "이전 음 beat_lv3" + Str(*p\beat_lv3)
    
  Else
    ;Debug "어디야"
    currentBar = barCount
    InitMySprite_lv3("note"+Str(inputTone+1), "graphics/graphics_lv3/lines"+Str(inputTone+1)+".png", x_lv3, y, 1, 1)
    bar_list_lv3(currentBar)\note_lv3()\num = inputTone+1
    If x_lv3<>800
      
            ;Debug PreviousElement(bar_list_lv3(currentBar)\note_lv3())
      
      Debug currentBar 
      Debug bar_list_lv3(currentBar)\note_lv3()
      
      *p.mySprite_lv3 = PreviousElement(bar_list_lv3(currentBar)\note_lv3())
      *p\beat_lv3 = beat_lv3
    EndIf
    
    If x_lv3 = 800
      ;숫자 마디 (비)활성화 
      For i=1 To 8
        *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i)+"_a")
        *p\active = 0
      Next
      *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+1)+"_a")
      *p\active = 1
      
    ElseIf x_lv3 = 1160
      ;숫자 마디 (비)활성화 
      For i=1 To 8
        *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i)+"_a")
        *p\active = 0
      Next
      
      *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+2)+"_a")
      *p\active = 1
    EndIf
     ;Debug "currentBar" + Str(currentBar)
    
  EndIf
  
  ;Debug bar_list_lv3(currentBar)\note_lv3()\beat_lv3
  ;Debug bar_list_lv3(currentBar)\note_lv3()\num 
EndProcedure

;화음 입력하면 개미랑 비료 그려주는 함수
Procedure AddChord_lv3(tone)

  chord = tone

  If chordCount < 8 Or editMode = 1
    
  ;수정모드
    If editMode = 1
      If check = 0
        check = check + 1
        ClearList(bar_list_lv3(currentBar)\chord())
        
        *p.mySprite_lv3 = FindSprite_lv3("ant")
        *p\active = 0
        *p.mySprite_lv3 = FindSprite_lv3("ant2")
        *p\active = 0
      Else
        check = 0
      EndIf 
      Debug "currentBar : " + Str(currentBar)
      Debug "listSize : " + Str(ListSize(bar_list_lv3(currentBar)\chord()))

    EndIf
    
    InitMySprite_lv3("antmove"+Str(currentBar), "graphics/graphics_lv3/antmove.png", Lv2_antX-200, Lv2_antY, 0)
    *p.mySprite_lv3 = FindSprite_lv3("antmove"+Str(currentBar))
    *p\f_horizontal = 4
    *p\f_width = 98
    *p\f_height = 112
 
    ;첫번째 화면의 첫번째 화음
    If ListSize(bar_list_lv3(currentBar)\chord()) = 0 And currentBar = 0
      InitMySprite_lv3("container"+Str(chordCount), "graphics/graphics_lv3/"+Str(chord+1)+".png", Lv2_contX, Lv2_contY, 2)
      
      *p2.mySprite_lv3 = bar_list_lv3(currentBar)\chord()
      *p2\num = tone+1
      
      ;showCurrentBar_lv3()
;edit모드      
;       For i=1 To 8
;         *p.mySprite_lv3 = FindSprite_lv3("bar_active_c"+Str(i))
;         If *p\active = 1
;           *p\active = 0
;           *p2.mySprite_lv3 = FindSpri
;         EndIf
;       Next
    
      
      InitMySprite_lv3("bar_active_c"+Str(currentBar*2+1), "graphics/graphics_lv3/"+Str(chord+1)+"_active.png", 70, 30, 0)
      InitMySprite_lv3("bar_c"+Str(currentBar*2+1), "graphics/graphics_lv3/"+Str(chord+1)+"s.png", 70+80*(currentBar*2), 30, 0,0)
      
      InitMyPosition_lv3(*p2, 10, 0, Lv2_antX+60, 0, 20)
      ;*p2\active = 1
      
      InitMyPosition_lv3(*p, 10, 0, Lv2_antX, 0, 20)
      MoveAnt_Lv3()
      *p\active = 0
      *p.mySprite_lv3 = FindSprite_lv3("ant2")
      *p\active = 1
      
      
      Debug "currentBar : " + Str(currentBar)
      Debug "listSize : " + Str(ListSize(bar_list_lv3(currentBar)\chord()))
        
    ;한 화면에서 두번째 마디  
    ElseIf ListSize(bar_list_lv3(currentBar)\chord()) = 1
      Debug "dho"
      InitMySprite_lv3("container"+Str(chordCount), "graphics/graphics_lv3/"+Str(chord+1)+".png", 920, Lv2_contY, 2)
      *p2.mySprite_lv3 = bar_list_lv3(currentBar)\chord()
      *p2\num = tone+1
      
      ;showCurrentBar_lv3()
      *b.mySprite_lv3 = FindSprite_lv3("bar_active_c"+Str(currentBar*2+1))
      *b\active = 0
      
      *b.mySprite_lv3 = FindSprite_lv3("bar_c"+Str(currentBar*2+1))
      *b\active = 1
      
      InitMySprite_lv3("bar_active_c"+Str(currentBar*2+2), "graphics/graphics_lv3/"+Str(chord+1)+"_active.png", 70+80*(currentBar*2+2-1), 30, 0)
      InitMySprite_lv3("bar_c"+Str(currentBar*2+2), "graphics/graphics_lv3/"+Str(chord+1)+"s.png", 70+80*(currentBar*2+2-1), 30, 0, 0)
      
      InitMyPosition_lv3(*p2, 10, 0, 1120, 0, 20)
      *p\x = 850
      InitMyPosition_lv3(*p, 10, 0, 1050, 0, 20)
      MoveAnt_Lv3()
      *p\active = 0
           
      *p.mySprite_lv3 = FindSprite_lv3("ant")
      *p\active = 1
      
      If editMode = 1
        editMode = 0
        Debug "수정 끝"
      EndIf
  
    ;화면 전환 후 첫번째 마디
    Else
      
      *b.mySprite_lv3 = FindSprite_lv3("background")
      *b\active = 0
      
      *b.mySprite_lv3 = FindSprite_lv3("background2")
      *b\active = 1
      
      If editMode = 0
        currentBar = currentBar + 1
        
        *p1.mySprite_lv3 = FindSprite_lv3("ant")
        *p1\active = 0
        *p1.mySprite_lv3 = FindSprite_lv3("ant2")
        *p1\active = 0
        
        ;전에 그린 화음 지우기
        For i=0 To 3 
          ForEach bar_list_lv3(i)\chord()
            bar_list_lv3(i)\chord()\active = 0
          Next
        Next
        
        DrawNote_lv3(currentBar)
        
      EndIf
      
      ;현재 입력한 화음만 활성화
      InitMySprite_lv3("container"+Str(chordCount), "graphics/graphics_lv3/"+Str(chord+1)+".png", Lv2_contX, Lv2_contY, 2)
      *p3.mySprite_lv3 = bar_list_lv3(currentBar)\chord()
      *p3\active = 1
      *p3\num = tone+1
      
      ;showCurrentBar_lv3()
      *b.mySprite_lv3 = FindSprite_lv3("bar_active_c"+Str((currentBar-1)*2+2))
      *b\active = 0
      
      *b.mySprite_lv3 = FindSprite_lv3("bar_c"+Str((currentBar-1)*2+2))
      *b\active = 1
      
      
      InitMySprite_lv3("bar_active_c"+Str(currentBar*2+1), "graphics/graphics_lv3/"+Str(chord+1)+"_active.png", 70+80*(currentBar*2), 30, 0)
      InitMySprite_lv3("bar_c"+Str(currentBar*2+1), "graphics/graphics_lv3/"+Str(chord+1)+"s.png", 70+80*(currentBar*2), 30, 0, 0)
      
      InitMyPosition_lv3(*p3, 10, 0, Lv2_antX+60, 0, 20)
      
      InitMyPosition_lv3(*p, 10, 0, Lv2_antX, 0, 20)
      MoveAnt_Lv3()
      *p\active = 0
      ;InitMySprite_lv3("ant2"+Str(currentBar), "graphics/graphics_lv3/ant.png", Lv2_antX, Lv2_antY,0)

      *p.mySprite_lv3 = FindSprite_lv3("ant2")
      *p\active = 1
      
    EndIf
    
  EndIf
  
EndProcedure


Procedure CalcBoxs_lv3()
  ptLeft = 0
  ptTop = 0
  ptRight = 0
  ptBottom = 0
  ptLength = 0
  direction = 0
  
  
  If inputMode = 0
    a = 7 ;음 입력
  Else
    a = 6 ;화음 입력
  EndIf
  
  
  If marker2X > marker1X
    ptLeft = marker1X
    ptRight = marker2X
  Else
    ptLeft = marker2X
    ptRight = marker1X
  EndIf
  
  If marker2Y > marker1Y
    ptTop = marker1Y
    ptBottom = marker2Y
  Else
    ptTop = marker2Y
    ptBottom = marker1Y
  EndIf
  
  If ptRight-ptLeft > ptBottom-ptTop
    ptLength = (ptRight-ptLeft)/a
    direction = 0
    top = (ptTop + ptBottom)/2 - 100
    bottom = (ptTop + ptBottom)/2 + 100
    If bottom > 480
      bottom = 480
    EndIf 
  Else
    ptLength = (ptBottom-ptTop)/a
    direction = 1
    left = (ptLeft + ptRight)/2 - 100
    right = (ptLeft + ptRight)/2 + 100
    If left < 0
      left = 0
    ElseIf right > 640
      right = 640
    EndIf       
  EndIf
  
  count = 0
  Repeat
    If direction = 1 ;세로
      bottom = ptBottom - count*ptLength
      top = ptBottom - (count+1)*ptLength      
    Else
      left = ptLeft + count*ptLength
      right = ptLeft + (count+1)*ptLength
    EndIf
    
    If left < 0
      left = 0
    EndIf
    If top < 0
      top = 0
    EndIf
    If right < 0
      right = 0
    EndIf
    If bottom < 0
      bottom = 0
    EndIf
    
    ptBox(count, 0)\x = left
    ptBox(count, 0)\y = top
    ptBox(count, 2)\x = right
    ptBox(count, 2)\y = bottom
    
    count+1
  Until count >= a
  
EndProcedure


Procedure DrawBoxs_lv3(*image)  
  ; 박스 0-6이 있고 각 꼭짓점을 4개 만듦, 현재는 0과 2만 씀(좌상단과 우하단) 타입은 CvPoint
  cvSetZero(*rectimg)
  
  ; 그리기 상태일 때 박스들의 좌표값을 계산한다.
  If markerState = 0
    CalcBoxs_lv3()
  EndIf
  
  ;멜로디 입력모드 
  If inputMode = 0
    ; 7개의 박스를 그린다
    count = 0
    Repeat
      cvRectangle(*rectimg, ptBox(count, 0)\x, ptBox(count, 0)\y, ptBox(count, 2)\x, ptBox(count, 2)\y, keyColor(count)\b, keyColor(count)\g, keyColor(count)\r, 0, -1, #CV_AA, #Null)
      count+1
    Until count >= 7
    
    cvAddWeighted(*image, 1, *rectimg, 0.5, 0, *image)
    cvResetImageROI(*image)
    
  ;화음 입력모드  
  Else
    If direction = 0   
      width = ptBox(5, 2)\x - ptBox(0, 0)\x
      height = ptBox(0, 2)\y - ptBox(0, 0)\y
    Else
      width = ptBox(0, 2)\x - ptBox(0, 0)\x
      height = ptBox(0, 2)\y - ptBox(5, 0)\y
    EndIf
    
    If height < 10 Or width < 10
      ProcedureReturn
    EndIf 
    
    
    ;Debug Str(ptBox(5,0)\x) + "    " + Str(ptBox(5,0)\y)
    ;Debug "width: " + Str(width) + "    height: " + Str(height)
    *boximg.IplImage = cvCreateImage(width, height, #IPL_DEPTH_8U, 3)
    
    If direction = 0
      cvResize(*loadbox1, *boximg, #CV_INTER_LINEAR)
      cvSetImageROI(*image, ptBox(0, 0)\x, ptBox(0, 0)\y, width, height)
    Else
      cvResize(*loadbox2, *boximg, #CV_INTER_LINEAR)
      cvSetImageROI(*image, ptBox(5, 0)\x, ptBox(5, 0)\y, width, height)
    EndIf
    
    cvAddWeighted(*image, 0.5, *boximg, 0.5, 0, *image)
    cvResetImageROI(*image)
    ;cvReleaseImage(*boximg)
  EndIf
  

EndProcedure


Procedure GetNote_lv3(note_lv3)
  result.i
  Select note_lv3
    Case 1
      result = 60
    Case 2
      result = 62
    Case 3
      result = 64
    Case 4
      result = 65
    Case 5
      result = 67
    Case 6
      result = 69
    Case 7
      result = 71
  EndSelect
  
  ProcedureReturn result
EndProcedure


Procedure GetChord(chord)
  Select chord
    Case #CHORD_C ;1번 코드
      note_lv3(0) = 1:      note_lv3(1) = 3:      note_lv3(2) = 5
    Case #CHORD_Dm
      note_lv3(0) = 2:      note_lv3(1) = 4:      note_lv3(2) = 6
    Case #CHORD_Em
      note_lv3(0) = 3:      note_lv3(1) = 5:      note_lv3(2) = 7
    Case #CHORD_F
      note_lv3(0) = 4:      note_lv3(1) = 6:      note_lv3(2) = 1
    Case #CHORD_G
      note_lv3(0) = 5:      note_lv3(1) = 7:      note_lv3(2) = 2
    Case #CHORD_Am
      note_lv3(0) = 6:      note_lv3(1) = 1:      note_lv3(2) = 3
      
  EndSelect
EndProcedure

Procedure PlayPianoSound_lv3(note_lv3)
  midiOutShortMsg_(hMidiOut, $90 | 0 | GetNote_lv3(note_lv3) << 8 | 127 << 16 )
  ;Delay(150) ;박자 별로 딜레이 수정하기
  ;midiOutShortMsg_(hMidiOut, $80 | 0 | GetNote_lv3(note_lv3) << 8 | 0 << 16)
EndProcedure

Procedure PlayChordSound_lv3()
  
  midiOutShortMsg_(hMidiOut, $90 | 0 | GetNote_lv3(note_lv3(0)) << 8 | 127 << 16 )
  midiOutShortMsg_(hMidiOut, $90 | 0 | GetNote_lv3(note_lv3(1)) << 8 | 127 << 16 )
  midiOutShortMsg_(hMidiOut, $90 | 0 | GetNote_lv3(note_lv3(2)) << 8 | 127 << 16 )
  ;Delay(1000)
  ;midiOutShortMsg_(hMidiOut, $80 | 0 | GetNote_lv3(note_lv3(0)) << 8 | 0 << 16)
  ;midiOutShortMsg_(hMidiOut, $80 | 0 | GetNote_lv3(note_lv3(1)) << 8 | 0 << 16)
  ;midiOutShortMsg_(hMidiOut, $80 | 0 | GetNote_lv3(note_lv3(2)) << 8 | 0 << 16)
  
EndProcedure

Procedure CalcArea_lv3(x, y)
  tone = -1
  i = 0
  a = 7
  
  If inputMode = 0
    a = 7
  Else
    a = 6
  EndIf
  
  Repeat
    If (ptBox(i, 0)\x < x) And (ptBox(i, 2)\x > x)
      If (ptBox(i, 0)\y < y) And (ptBox(i, 2)\y > y)
        tone = i
        Break
      EndIf
    EndIf
    i + 1
  Until i >= a
  
  ProcedureReturn tone ; 음을 반환
EndProcedure


Procedure CheckArea_lv3(key)
  If(key = #PB_Key_2)
    ;    Debug("GREEN : " + Str(marker2X) + ", " + Str(marker2Y))
    tone = CalcArea_lv3(marker2X, marker2Y)
  ElseIf(key = #PB_Key_1)
    ;    Debug("RED : " + Str(marker1X) + ", " + Str(marker1Y))
    tone = CalcArea_lv3(marker1X, marker1Y)
  EndIf
  

  ; 음 입력모드인 경우 + 음이 도-시 사이인 경우만 출력
  If tone > -1 And tone < 7 And inputMode = 0
    ;이전 음 소리 제거
    If inputCount <> -1
       midiOutShortMsg_(hMidiOut, $80 | 0 | GetNote_lv3(bar_list_lv3(currentBar)\note_lv3()\num) << 8 | 0 << 16)
    EndIf 
    
    intervalEnd = intervalStart
    intervalStart = GetTickCount_()
    
    inputTone = tone
    
    AddNote_lv3()
 
    If barCount < 4
      PlayPianoSound_lv3(tone+1)
      ;answerTone = tone
      inputCount = inputCount + 1
      
    EndIf
    
     
  ; 화음 입력모드
  ElseIf inputMode = 1 And tone > -1 And tone < 6 
    GetChord(tone+1)
    PlayChordSound_lv3()
    AddChord_lv3(tone)
    If editMode = 0
      chordCount = chordCount + 1
    EndIf
    
  EndIf
    
EndProcedure


Procedure ClearNote()
  ;Shared Mutex
  For i=0 To 3 
    ForEach bar_list_lv3(i)\note_lv3()
      bar_list_lv3(i)\note_lv3()\active = 0
    Next
    
    ForEach bar_list_lv3(i)\chord()
      bar_list_lv3(i)\chord()\active = 0
    Next

  Next
  
  
  ForEach sprite_list_lv3()
    FrameManager_lv3(sprite_list_lv3()) ;active 상태인 것들만 다음 프레임으로
  Next
  
  
  For i=0 To 3
    currentTime = GetTickCount_()
    ForEach bar_list_lv3(i)\note_lv3()
      FrameManager_lv3(bar_list_lv3(i)\note_lv3())
    Next
    
    currentTime = GetTickCount_()
    ForEach bar_list_lv3(i)\chord()
      FrameManager_lv3(bar_list_lv3(i)\chord())
    Next
  Next
  
  
  ClearScreen(RGB(255, 255, 255))
  
  ForEach sprite_list_lv3()
    DrawMySprite_lv3(sprite_list_lv3())
  Next
  
  
  For i=0 To 3 
    ForEach bar_list_lv3(i)\note_lv3()
      DrawMySprite_lv3(bar_list_lv3(i)\note_lv3())
    Next
    
    ForEach bar_list_lv3(i)\chord()
      DrawMySprite_lv3(bar_list_lv3(i)\chord())
    Next
    
  Next
EndProcedure


;전체 재생해주는 함수
Procedure PlayAll()
  
  Repeat
 
    ClearNote()
    j=0
    ForEach bar_list_lv3(i)\note_lv3()
 
      note_lv3 = bar_list_lv3(i)\note_lv3()\num
      beat_lv3 = bar_list_lv3(i)\note_lv3()\beat_lv3
      
      bar_list_lv3(i)\note_lv3()\active = 1
      currentTime = GetTickCount_()
      FrameManager_lv3(bar_list_lv3(i)\note_lv3())
      DrawMySprite_lv3(bar_list_lv3(i)\note_lv3())
  
      If bar_list_lv3(i)\note_lv3()\x = 800
        *p.mySprite_lv3 = FirstElement(bar_list_lv3(i)\chord())
        chord = *p\num
        *p\active = 1
        GetChord(chord)
        PlayChordSound_lv3()
        j = j + 1
        
      ElseIf bar_list_lv3(i)\note_lv3()\x = 1160
        *p.mySprite_lv3 = LastElement(bar_list_lv3(i)\chord())
        chord = *p\num
        *p\active = 1
        GetChord(chord)
        PlayChordSound_lv3()
        j = j + 1
      EndIf  
      
      FrameManager_lv3(bar_list_lv3(i)\chord())
      DrawMySprite_lv3(bar_list_lv3(i)\chord())
        
      midiOutShortMsg_(hMidiOut, $90 | 0 | GetNote_lv3(note_lv3) << 8 | 127 << 16 )
      Delay(beat_lv3)
      midiOutShortMsg_(hMidiOut, $80 | 0 | GetNote_lv3(note_lv3) << 8 | 0 << 16)
      
      FlipBuffers()
      
    Next

  i = i + 1
  Until i = 4
  
EndProcedure


Procedure Scoring_lv3()
  ;list score 마디별로 결과 저장하기
  Dim checkNote.Bar_lv3(7)
  
  For i=0 To 3
    ForEach bar_list_lv3(i)\note_lv3()
      *p.mySprite_lv3 = bar_list_lv3(i)\note_lv3()
      ;강박인 음을 기준으로 채점(마디 첫음 혹은 길이가 긴 음)
      If *p\x = 800
        *p\num = AddElement(checkNote(2*i)\note_lv3())
      ElseIf *p\x = 1160
        *p\num = AddElement(checkNote(2*i+1)\note_lv3())
      ElseIf *p\beat_lv3 = 600
        If *p\x < 1160
          *p\num = AddElement(checkNote(2*i)\note_lv3())
        Else
          *p\num = AddElement(checkNote(2*i+1)\note_lv3())
        EndIf
      EndIf
    Next

    ForEach bar_list_lv3(i)\chord()
      ;checkNote랑 화음 비교
      ;checkNote(
        
    Next
      
      
        ;While NextElement(checkNote(i)\note_lv3())
          ; This is OK since the first call to NextElement() will move the current element to the first item in the list
          ;MessageRequester("Score", Str(Scores()), #PB_MessageRequester_Ok)
        ;Wend
  Next
EndProcedure

Procedure CreateLEVEL3()
  
    Shared MainWindow
  
markerState = 0 ; 마커 입력 상태

keyColor(0)\r = 216
keyColor(0)\g = 63
keyColor(0)\b = 34
keyColor(1)\r = 234
keyColor(1)\g = 143
keyColor(1)\b = 49
keyColor(2)\r = 246
keyColor(2)\g = 224
keyColor(2)\b = 20
keyColor(3)\r = 144
keyColor(3)\g = 200
keyColor(3)\b = 75
keyColor(4)\r = 0
keyColor(4)\g = 57
keyColor(4)\b = 137
keyColor(5)\r = 135
keyColor(5)\g = 80
keyColor(5)\b = 46
keyColor(6)\r = 104
keyColor(6)\g = 25
keyColor(6)\b = 146

;InitProblem_lv3()


;MIDI 설정
OutDev.l
result = midiOutOpen_(@hMidiOut, OutDev, 0, 0, 0)

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(0)
Until nCreate = 5 Or *capture

If *capture
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)
  *image.IplImage : pbImage = CreateImage(#PB_Any, 640, 480)
  *rectimg = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *loadbox1 = cvLoadImage("graphics/graphics_lv3/chord_box.png", 1)
  *loadbox2 = cvLoadImage("graphics/graphics_lv3/chord_box2.png", 1)
  
  
  ;전체화면으로 실행
 ; If OpenWindow(0, 0, 0, FrameWidth, FrameHeight, "PureBasic Interface to OpenCV", #PB_Window_SystemMenu |#PB_Window_MaximizeGadget | #PB_Window_ScreenCentered|#PB_Window_Maximize)
    If MainWindow   
    OpenWindow(1, 0, WindowHeight(0)/2 - 200, FrameWidth-5, FrameHeight-30, "title") ; 웹캠용 윈도우
    ImageGadget(0, 0, 0, FrameWidth, FrameHeight, ImageID(pbImage))
    StickyWindow(1, #True) ; 항상 위에 고정
    SetWindowLongPtr_(WindowID(1), #GWL_STYLE, GetWindowLongPtr_(WindowID(1), #GWL_STYLE)&~ #WS_THICKFRAME &~ #WS_DLGFRAME) ; 윈도우 타이틀 바 제거
    SetForegroundWindow_(WindowID(0))
    InitSprite()
    InitKeyboard()
    
    ;Screen과 Sprite 생성
    ;Screen_0 = OpenWindowedScreen(WindowID(Window_0), 0, 0, WindowWidth(0), WindowHeight(0))
    
    UsePNGImageDecoder()
    
    TransparentSpriteColor(#PB_Default, RGB(255, 0, 255))
    
    InitMySprite_lv3("background", "graphics/graphics_lv3/background.png", 0, 0, 0)
    InitMySprite_lv3("background2", "graphics/graphics_lv3/background2.png", 0, 0, 0, 0)
    InitMySprite_lv3("leaf1", "graphics/graphics_lv3/leaf.png", 1120, 165, 0)
    InitMySprite_lv3("leaf2", "graphics/graphics_lv3/leaf.png", 1480, 170, 0)
    InitMySprite_lv3("note1", "graphics/graphics_lv3/do.png", 0, 650, 0, 0)
    InitMySprite_lv3("note2", "graphics/graphics_lv3/re.png", 0, 650, 0, 0)
    InitMySprite_lv3("note3", "graphics/graphics_lv3/mi.png", 0, 650, 0, 0)
    InitMySprite_lv3("note4", "graphics/graphics_lv3/fa.png", 0, 650, 0, 0)
    InitMySprite_lv3("note5", "graphics/graphics_lv3/so.png", 0, 650, 0, 0)
    InitMySprite_lv3("note6", "graphics/graphics_lv3/la.png", 0, 650, 0, 0)
    InitMySprite_lv3("note7", "graphics/graphics_lv3/ti.png", 0, 650, 0, 0)
    
    InitMySprite_lv3("ant", "graphics/graphics_lv3/ant.png", 1050, Lv2_antY,0,0)
    InitMySprite_lv3("ant2", "graphics/graphics_lv3/ant.png", Lv2_antX, Lv2_antY,0,0)

    
    ;숫자 마디
    InitMySprite_lv3("bar1", "graphics/graphics_lv3/bar1.png", 70, 30, 0, 1)
    InitMySprite_lv3("bar2", "graphics/graphics_lv3/bar2.png", 150, 30, 0, 1)
    InitMySprite_lv3("bar3", "graphics/graphics_lv3/bar3.png", 230, 30, 0, 1)
    InitMySprite_lv3("bar4", "graphics/graphics_lv3/bar4.png", 310, 30, 0, 1)
    InitMySprite_lv3("bar5", "graphics/graphics_lv3/bar5.png", 390, 30, 0, 1)
    InitMySprite_lv3("bar6", "graphics/graphics_lv3/bar6.png", 470, 30, 0, 1)
    InitMySprite_lv3("bar7", "graphics/graphics_lv3/bar7.png", 550, 30, 0, 1)
    InitMySprite_lv3("bar8", "graphics/graphics_lv3/bar8.png", 630, 30, 0, 1)
    
    InitMySprite_lv3("bar1_a", "graphics/graphics_lv3/bar1_active.png", 70, 30, 0, 1)    
    InitMySprite_lv3("bar2_a", "graphics/graphics_lv3/bar2_active.png", 150, 30, 0, 0)  
    InitMySprite_lv3("bar3_a", "graphics/graphics_lv3/bar3_active.png", 230, 30, 0, 0)     
    InitMySprite_lv3("bar4_a", "graphics/graphics_lv3/bar4_active.png", 310, 30, 0, 0)    
    InitMySprite_lv3("bar5_a", "graphics/graphics_lv3/bar5_active.png", 390, 30, 0, 0)  
    InitMySprite_lv3("bar6_a", "graphics/graphics_lv3/bar6_active.png", 470, 30, 0, 0)    
    InitMySprite_lv3("bar7_a", "graphics/graphics_lv3/bar7_active.png", 550, 30, 0, 0)
    InitMySprite_lv3("bar8_a", "graphics/graphics_lv3/bar8_active.png", 630, 30, 0, 0)
    
    ;화음 마디
    InitMySprite_lv3("c1", "graphics/graphics_lv3/container_s.png", 70, 30, 0, 0)
    InitMySprite_lv3("c2", "graphics/graphics_lv3/container_s.png", 150, 30, 0, 0)
    InitMySprite_lv3("c3", "graphics/graphics_lv3/container_s.png", 230, 30, 0, 0)
    InitMySprite_lv3("c4", "graphics/graphics_lv3/container_s.png", 310, 30, 0, 0)
    InitMySprite_lv3("c5", "graphics/graphics_lv3/container_s.png", 390, 30, 0, 0)
    InitMySprite_lv3("c6", "graphics/graphics_lv3/container_s.png", 470, 30, 0, 0)
    InitMySprite_lv3("c7", "graphics/graphics_lv3/container_s.png", 550, 30, 0, 0)
    InitMySprite_lv3("c8", "graphics/graphics_lv3/container_s.png", 630, 30, 0, 0)
      
    x_note1 = 800
    x_note2 = 840
    y_note1 = 610
   
    ClearScreen(RGB(255, 255, 255))
    
    Repeat
      *image = cvQueryFrame(*capture)
      ;*image = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
      
      If *image
        cvFlip(*image, #Null, 1)
        
        currentTime = GetTickCount_()
        
                ForEach sprite_list_lv3()
          FrameManager_lv3(sprite_list_lv3()) ;active 상태인 것들만 다음 프레임으로
        Next
        
        
        For i=0 To 3
          currentTime = GetTickCount_()
          ForEach bar_list_lv3(i)\note_lv3()
            FrameManager_lv3(bar_list_lv3(i)\note_lv3())
          Next
          
          currentTime = GetTickCount_()
          ForEach bar_list_lv3(i)\chord()
            FrameManager_lv3(bar_list_lv3(i)\chord())
          Next
        Next
       
        
        ClearScreen(RGB(255, 255, 255))
        
        ForEach sprite_list_lv3()
          DrawMySprite_lv3(sprite_list_lv3())
        Next
        
        
        For i=0 To 3 
          ForEach bar_list_lv3(i)\note_lv3()
            DrawMySprite_lv3(bar_list_lv3(i)\note_lv3())
          Next
          
          ForEach bar_list_lv3(i)\chord()
            DrawMySprite_lv3(bar_list_lv3(i)\chord())
          Next
          
        Next


        ;- 키보드 이벤트
        ExamineKeyboard()
        
        If KeyboardReleased(#PB_Key_1)
          keyInput = #PB_Key_1
          GetCursorPos_(mouse.POINT) : mouse_x=mouse\x : mouse_y=mouse\y
          marker1X = mouse_x
          marker1Y = mouse_y - (WindowHeight(0)/2 - 200)
          ;marker1Y = mouse_y - (WindowHeight(0)- FrameHeight + 20)
          If (markerState = 1)
            CheckArea_lv3(keyInput)
          EndIf
        EndIf
        
        If KeyboardReleased(#PB_Key_2)
          keyInput = #PB_Key_2
          GetCursorPos_(mouse.POINT) : mouse_x=mouse\x : mouse_y=mouse\y
          marker2X = mouse_x
          marker2Y = mouse_y - (WindowHeight(0)/2 - 200)
          ;marker2Y = mouse_y - (WindowHeight(0)- FrameHeight + 20)
          If (markerState = 1)
            CheckArea_lv3(keyInput)
          EndIf
        EndIf
        
        If KeyboardReleased(#PB_Key_Space)
          markerState = 1
        EndIf
        
        ;입력 모드 변경_ 0이면 음 입력, 1이면 화음 입력
        If KeyboardReleased(#PB_Key_3)
          If inputMode = 0
            inputMode = 1
            currentBar = 0
            DrawNote_lv3(currentBar)
            ;숫자 마디 비활성화
            For i=1 To 8
              *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i))
              *p\active = 0
              *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i)+"_a")
              *p\active = 0
            Next
            
            
            For i=1 To 8
              *p.mySprite_lv3 = FindSprite_lv3("c"+Str(i))
              *p\active = 1
            Next
            
            
            *b.mySprite_lv3 = FindSprite_lv3("background")
            *b\active = 1
            
            *b.mySprite_lv3 = FindSprite_lv3("background2")
            *b\active = 0
            
          Else
            inputMode = 0
            
          EndIf
        EndIf
        
        
        ;입력모드 <-> 수정모드
        If KeyboardReleased(#PB_Key_4)
          If editMode = 0
            Debug "수정모드"
            editMode = 1
            inputCount = -1 ;멜로디 수정 시에만
          Else
            editMode = 0
            Debug "입력모드"
          EndIf
        EndIf
        
        
        ;앞의 마디로 이동
        If KeyboardReleased(#PB_Key_Left)
          If currentBar > 0
            ;Debug currentBar-1
            currentBar = currentBar-1 
            
            ;숫자 마디 비활성화
            For i=1 To 8
              *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i)+"_a")
              *p\active = 0
            Next
            
            *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+1)+"_a")
            *p\active = 1
            
            *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+2)+"_a")
            *p\active = 1
            
            DrawNote_lv3(currentBar)
            ;Debug "마디이동, 현재 마디는?" + Str(currentBar)

          EndIf
        EndIf
        
        ;뒤의 마디로 이동
        If KeyboardReleased(#PB_Key_Right)
          If currentBar < 3 And barCount > currentBar 
             currentBar = currentBar+1
             ;숫자 마디 비활성화
             For i=1 To 8
               *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(i)+"_a")
               *p\active = 0
             Next
             
             *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+1)+"_a")
             *p\active = 1
             
             *p.mySprite_lv3 = FindSprite_lv3("bar"+Str(currentBar*2+2)+"_a")
             *p\active = 1
            
             DrawNote_lv3(currentBar)
             ;Debug "마디이동, 현재 마디는?" + Str(currentBar) 
          EndIf
        EndIf
        
        
        ;전체 재생
        If KeyboardReleased(#PB_Key_0)
          PlayAll()
        EndIf
        
        ;--채점
        If KeyboardReleased(#PB_Key_9)
          ;1. 코드 진행 체크
          
          ;2. 멜로디x코드 올바른지 체크
          Scoring_lv3()
          
          For i=0 To 7
            If score(i) = 0
              ;InitSprite 녹색 동그라미
              
            Else
              ;InitSprite 빨간 동그라미
            EndIf
          Next
          
          InitMySprite_lv3("o", "graphics/graphics_lv3/result_o.png", 70, 30, 0, 0)
          InitMySprite_lv3("x", "graphics/graphics_lv3/result_x.png", 230, 30, 0, 0)
          ;InitMySprite_lv3("c1", "graphics/graphics_lv3/container_s.png", 70, 30, 0, 0)
              
        EndIf
  
      EndIf
      
      DrawBoxs_lv3(*image)
      
      *mat.CvMat = cvEncodeImage(".bmp", *image, 0)     
      Result = CatchImage(1, *mat\ptr)
      SetGadgetState(0, ImageID(1))     
      cvReleaseMat(@*mat)  
      
      FlipBuffers()
      
      
      
     If  KeyboardPushed(#PB_Key_0)
       
     FreeImage(pbImage)
     cvReleaseCapture(@*capture)
     midiOutReset_(hMidiOut)
     midiOutClose_(hMidiOut)
     CloseWindow(1)

      Break 
   
    EndIf 
      
      
    Until WindowEvent() = #PB_Event_CloseWindow Or KeyboardReleased(#PB_Key_0)
  EndIf
  
  
  
   ; FreeImage(pbImage)
 ; cvReleaseCapture(@*capture)
 ; midiOutReset_(hMidiOut)
 ; midiOutClose_(hMidiOut)
 ;      CloseWindow(1)
;  ForEach sprite_list_lv3()
 ;   FreeStructure(sprite_list_lv3())
;  Next
  
 ; For i=0 To 3 
 ;   ForEach bar_list_lv3(i)\note_lv3()
 ;     FreeStructure(bar_list_lv3(i)\note_lv3())
 ;   Next
 ;   
 ;   ForEach bar_list_lv3(i)\chord()
 ;     FreeStructure(bar_list_lv3(i)\chord())
 ;   Next
 ;   
 ; Next
  
  
  
  
Else
  MessageRequester("PureBasic Interface to OpenCV", "Unable to connect to a webcam - operation cancelled.", #MB_ICONERROR)
EndIf

Debug "level3 정상종료?"


EndProcedure

;CreateLEVEL3()


; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 18
; FirstLine = 6
; Folding = AAAA+
; EnableXP
; DisableDebugger