from playwright.sync_api import sync_playwright
import os

def final_crop():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 1000, "height": 1000})

        img_path = os.path.abspath('assets/images/full_logo.jpg')
        html_content = f"""
        <html>
        <body style="margin: 0; padding: 0; background: black; display: flex; justify-content: center; align-items: center; height: 100vh;">
            <img src="file://{img_path}" style="width: 100%; height: 100%; object-fit: contain;">
        </body>
        </html>
        """

        page.set_content(html_content)
        page.wait_for_timeout(1000)

        # Based on debug_find.png, the text is in the middle.
        # RIYOO is roughly from x=380 to x=620 on a 1000px wide screen if object-fit contain is used.
        # Wait, the image box was {'x': 263, 'y': 0, 'width': 472, 'height': 999}
        # So image x is 263 to 735.
        # In the image, text is centered.
        # Let's try to crop the left part of the text.
        page.screenshot(path="assets/images/logo.png", clip={"x": 380, "y": 480, "width": 80, "height": 80})
        browser.close()

if __name__ == "__main__":
    final_crop()
