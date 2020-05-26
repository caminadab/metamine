#ifndef UNICODE
#define UNICODE
#endif 

#include <windows.h>

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hInstance2, PSTR pCmdLine, int nCmdShow)
{
    // Register the window class.
    const wchar_t CLASS_NAME[]  = L"Metamine";
    
    WNDCLASS wc = { };

    wc.lpfnWndProc   = WindowProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;
		wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
		wc.hCursor = LoadIcon(NULL, IDC_ARROW);
		
		SetConsoleOutputCP(CP_UTF8);
		WriteConsole(GetStdHandle(STD_OUTPUT_HANDLE), L"hoi", 3, NULL, 0);

		unsigned int num;
		WriteConsole(GetStdHandle(STD_OUTPUT_HANDLE), L"hoi\n", 4, &num, 0);

    RegisterClass(&wc);

    // Create the window.

    HWND hwnd = CreateWindowEx(
        0,                              // Optional window styles.
        CLASS_NAME,                     // Window class
        L"Metamine",    // Window text
        WS_OVERLAPPEDWINDOW,            // Window style

        // Size and position
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,

        NULL,       // Parent window    
        NULL,       // Menu
        hInstance,  // Instance handle
        NULL        // Additional application data
        );

    if (hwnd == NULL)
    {
        return 0;
    }

		unsigned long long int n = 1;
		SetTimer(hwnd, &n, 16, 0);

    ShowWindow(hwnd, nCmdShow);

    // Run the message loop.

    MSG msg = { };
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

int muisX = 0;
int muisY = 0;
int i = 0;
float looptijd = 0.0f;

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;

		case WM_MOUSEMOVE:
		{
			muisX = LOWORD(lParam);
			muisY = HIWORD(lParam);
			return 0;
		}

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            FillRect(hdc, &ps.rcPaint, (HBRUSH) (COLOR_WINDOW+3));

						HBRUSH hBrush = CreateSolidBrush(RGB(200,0,50));
						SelectObject(hdc, hBrush);
						POINT x = {0, 0};
						POINT y = {muisX, muisY};
						POINT z = { + 100, looptijd * 1.0f + 500}; //muisX, muisY};
						looptijd = looptijd + 1.0f/60.0f;
						i ++;
						POINT w = {0, looptijd / 10};
						POINT pt[] = {x, y, z, w};
						SetPolyFillMode(hdc, WINDING);
						Polygon(hdc, pt, 4);

            EndPaint(hwnd, &ps);
						ReleaseDC(hwnd, hdc);

        }
        return 0;

		case WM_KEYDOWN:
			WriteConsole(GetStdHandle(STD_OUTPUT_HANDLE), "hoi", 3, NULL, 0);
			return 0;

		case WM_TIMER:
		{
			InvalidateRect(hwnd, NULL, 0);
			RedrawWindow(hwnd, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW);
			unsigned int n = 1;
			SetTimer(hwnd, 0, 16, NULL);
			return 0;
		}
	}
	return DefWindowProc(hwnd, uMsg, wParam, lParam);
}
