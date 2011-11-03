;;; posn-on-screen.el --- Find the coordinates (x, y) around point on screen

;; Copyright (C) 2011

;; Author:  <guillaume.papin@epitech.eu>
;; Keywords: convenience, frames, help

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package aimed to provide one or more functions to get
;; informations about the position on the screen of a visible point.
;; With this information someone can create a frame near the point and
;; provide a completion UI for example.
;;
;; Why make a package for such a small thing ?
;; Because I saw more than one Emacs package doing that thing and I
;; needed it too. I prefer to do that in a separate file because:
;; - it can be used by one or more package
;; - it can be enhanced to handle different window systems more
;;   accurately
;;
;; Note: At the moment of this writing the code is shamelessly stolen
;; from the esense package.
;;
;; Here is a list of packages that implements similar routines inside
;; their code.
;; - http://esense.sourceforge.net
;; - http://www.emacswiki.org/PosTip
;; - http://www.emacswiki.org/emacs/tooltip-help.el
;; - http://code.google.com/p/csense/source/browse/trunk/csense.el
;; - `dframe-reposition-frame-emacs' in dframe.el (shipped with Emacs)

;;; Code:

(if (eq window-system 'w32)
    (defcustom posn-on-screen-titlebar-height 30
      "Height of Emacs window titlebar. It mostly depends on your window
manager settings. Correct titlebar height will help Posn-On-Screen to display
popup windows in a proper position."
      :type 'integer
      :group 'posn-on-screen)

  (defconst posn-on-screen-titlebar-height 0
    "On Linux the title bar is not the part of the window, so we
don't have to consider its height in calculations."))

(defun get-point-pixel-position ()
  "Return the position of point in pixels within the frame."
  (let ((point-pos (posn-on-screen-point-position)))
    (posn-on-screen-get-pixel-position (car point-pos) (cdr point-pos))))

(defun posn-on-screen-get-pixel-position (x y)
  "Return the pixel position of location X Y (1-based) within the frame."
  (let ((old-mouse-pos (mouse-position)))
    (set-mouse-position (selected-frame)
                        ;; the fringe is the 0th column, so x is OK
                        x
                        (1- y))
    (let ((point-x (car (cdr (mouse-pixel-position))))
          (point-y (cdr (cdr (mouse-pixel-position)))))
      ;; on Linux with the Enlightenment window manager restoring the
      ;; mouse coordinates didn't work well, so for the time being it
      ;; is enabled for Windows only
      (when (eq window-system 'w32)
        (set-mouse-position
         (selected-frame)
         (cadr old-mouse-pos)
         (cddr old-mouse-pos)))
      (cons point-x point-y))))

(eval-and-compile
  (if (fboundp 'window-inside-edges)
      ;; Emacs devel.
      (defalias 'posn-on-screen-window-edges
        'window-inside-edges)
    ;; Emacs 21
    (defalias 'posn-on-screen-window-edges
      'window-edges)))

(defun posn-on-screen-point-position ()
  "Return the location of POINT as positioned on the selected frame.
Return a cons cell (X . Y)"
  (let* ((w (selected-window))
         (f (selected-frame))
         (edges (posn-on-screen-window-edges w))
         (col (current-column))
         (row (count-lines (window-start w) (point)))
         (x (+ (car edges) col))
         (y (+ (car (cdr edges)) row)))
    (cons x y)))

(defun posn-on-screen (width height preferred-pos &optional x y)
  "Calculate pixel position of a rectangle with size WIDTH*HEIGHT
at X;Y or point if they are not given and return a list (X . Y)
containing the calculated position. Ensure the rectangle does not
cover the position. PREFERRED-POS can either be the symbol
`above' or `below' indicating the preferred position of the popup
relative to point."
  (if (and x
           (> x (frame-width)))
      (setq x (frame-width)))

  (let* ((fx (frame-parameter nil 'left))
         (fy (frame-parameter nil 'top))
         (fw (frame-pixel-width))
         (fh (frame-pixel-height))

         ;; handles the case where (frame-parameter nil 'top) or
         ;; (frame-parameter nil 'left) return something like (+ -4).
         ;; This was the case where e.g. Emacs window is maximized, at
         ;; least on Windows XP. The handling code is "shamelessly
         ;; stolen" from cedet/speedbar/dframe.el
         ;;
         ;; (contributed by Andrey Grigoriev)
         (frame-left (if (not (consp fx))
                         fx
                       ;; If fx is a list, that means we grow
                       ;; from a specific edge of the display.
                       ;; Convert that to the distance from the
                       ;; left side of the display.
                       (if (eq (car fx) '-)
                           ;; A - means distance from the right edge
                           ;; of the display, or DW - fx - framewidth
                           (- (x-display-pixel-width) (car (cdr fx)) fw)
                         (car (cdr fx)))))

         (frame-top (if (not (consp fy))
                        fy
                      ;; If fy is a list, that means we grow
                      ;; from a specific edge of the display.
                      ;; Convert that to the distance from the
                      ;; left side of the display.
                      (if (eq (car fy) '-)
                          ;; A - means distance from the right edge
                          ;; of the display, or DW - pfx - framewidth
                          (- (x-display-pixel-height) (car (cdr fy)) fh)
                        (car (cdr fy)))))

         (point-x (car (if x
                           (posn-on-screen-get-pixel-position x y)
                         (get-point-pixel-position))))
         (point-y (cdr (if y
                           (posn-on-screen-get-pixel-position x y)
                         (get-point-pixel-position))))

         (corner-x (let ((x (+ point-x
                               frame-left
                               ;; a small offset is added to the x
                               ;; position, so that it's a little
                               ;; to the right from the position
                               ;; (without this offset the tooltip
                               ;; and the mouse cursor sometimes
                               ;; overlap each other and the tooltip
                               ;; is hidden immediately)
                               (* 2 (frame-char-width)))))
                     (if (< (+ x width)
                            (display-pixel-width))
                         x
                       (- (display-pixel-width) width))))

         (real-y-offset (+ point-y
                           frame-top
                           posn-on-screen-titlebar-height
                           ;; menu bar height
                           (let ((n-lines (frame-parameter nil 'menu-bar-lines)))
                             ;; FIXME: It's a bit tricky. Menu font
                             ;; isn't necessarily the same as frame font
                             ;; so frame-char-height may return
                             ;; completely wrong number.
                             (* n-lines (frame-char-height)))))

         (y-above (- real-y-offset
                     (+ height
                        ;; add two rows to the height
                        ;; so that the popup does not
                        ;; cover the current line
                        (* 2 (frame-char-height)))))

         (y-below (+ real-y-offset
                     ;; add a row to the height
                     ;; so that the popup does not
                     ;; cover the current line
                     (frame-char-height)))

         (corner-y (if (eq preferred-pos 'above)
                       y-above
                     y-below)))

    (if (< corner-y 0)
        (setq corner-y y-below))

    (if (> (+ corner-y height)
           (display-pixel-height))
        (setq corner-y y-above))

    (cons corner-x corner-y)))

(provide 'posn-on-screen)
;;; posn-on-screen.el ends here
