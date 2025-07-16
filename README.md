\# 🌍 Satellite Imagery Change Detection App  

\*\*Computer Vision Challenge SS2025 – Group 13\*\*



\## 👥 Creators

\- Haosong Li  

\- Qian Liu  

\- Tian Qin  

\- Kevin Tong  

\- Jiaheng Zhao  

\- Jiachen Zhong  



---



\## ⚙️ Requirements

\- \*\*MATLAB version\*\*: `R2025a`

\- \*\*Toolboxes\*\*:

&nbsp; - Computer Vision Toolbox – Version `25.1`

&nbsp; - Image Processing Toolbox – Version `25.1`



---



\## 📖 User Guide



\### 1. Launch the App

Run the main file:

```matlab

main.m

```

This opens the interactive GUI.



---



\### 2. Select a Dataset

\- Click \*\*`Select Image`\*\* or directly click on a location on the rotating globe.

\- To use a custom dataset, create a new folder under the `/Datasets` directory.

\- Image filenames must follow the format:

&nbsp; ```

&nbsp; YYYY\_MM.jpg / .png / .bmp / .tif / .tiff

&nbsp; ```



---



\### 3. Preprocess the Images  

Click the \*\*`Preprocess`\*\* button. Choose from the following modes:



| Mode             | Description                                                                 |

|------------------|-----------------------------------------------------------------------------|

| `Auto`           | Automatically selects between Retinex, Brightness-only, or Skip             |

| `Basic`          | Histogram equalization on each color channel                                |

| `Retinex`        | Enhanced Retinex-based image enhancement                                     |

| `Brightness-only`| Adaptive histogram equalization (useful for dark images)                    |

| `Skip`           | No enhancement (only bilateral filtering and cropping applied)              |



🗂 Preprocessed images will be saved to the `.cache/` folder.



---



\### 4. Align the Images  

Click \*\*`Align Images`\*\*. You will manually select 4–10 feature points.



\*\*Tips for selecting points:\*\*

\- Choose stable features: rivers, rooftops, coastlines  

\- Spread them across the image  

\- Avoid moving objects like cars or trees  

\- Avoid points near image edges  



🛠 Controls:

\- Press `Backspace` to undo the last point  

\- Press `Enter` to confirm selection  



Images will be aligned using the first image as reference and saved in `.cache/`.



---



\### 5. Visualization Tools



> \*\*Note:\*\* Use steps 5.1 and 5.2 before accessing 5.3 and 5.4



\#### 5.1 `Align Visual`

\- Step-by-step visual alignment

\- Use the slider to control animation steps and opacity



\#### 5.2 `Blended Image`

\- Blend selected images to compare visually

\- Set transparency level per image



\#### 5.3 `Difference Highlight`

\- Compare two images and visualize differences

\- Increasing threshold = fewer differences shown



\#### 5.4 `Heatmap`

\- Visualize intensity of change as a heatmap  

\- Threshold for binary mask is fixed to 75  

\- Heatmap threshold is adjustable



---



\### 6. Analysis Tools



| Tool            | Description                                                           |

|-----------------|-----------------------------------------------------------------------|

| `Zoom in/out`   | Interactive zoom function                                             |

| `Time Slider`   | Animates image set; speed based on slider value                      |

| `Select Area`   | Highlights pre-defined regions depending on the dataset              |



---



\## 💡 Tips \& Shortcuts



\- \*\*Tips button\*\*: Shows usage instructions

\- \*\*Rotate the globe\*\*: Click and drag

\- \*\*Browse images\*\*: Use `Previous` / `Next` buttons

\- \*\*Clear memory\*\*: Use `Clear Cache`

\- \*\*Reset\*\*: Returns to globe view

\- \*\*Exit\*\*: Closes the app



---



\## 📚 References



1\. Funt, B. (2004). \*Retinex in MATLAB™\*. Journal of Electronic Imaging, 13(1), 48.  

&nbsp;  https://doi.org/10.1117/1.1636761



2\. Burkardt, J. (2009). \*K-Means Clustering\*, Virginia Tech.  

&nbsp;  https://people.sc.fsu.edu/~jburkardt/classes/isc\_2009/clustering\_kmeans.pdf



3\. Rublee, E., Rabaud, V., Konolige, K., \& Bradski, G. (2011).  

&nbsp;  \*ORB: An efficient alternative to SIFT or SURF\*. ICCV, 2564–2571.  

&nbsp;  https://doi.org/10.1109/iccv.2011.6126544


4\. Zhu, Y., & Huang, C. (2012). An adaptive histogram equalization 

&nbsp; algorithm on the image gray level mapping. Physics Procedia, 25, 601–608. 

&nbsp; https://doi.org/10.1016/j.phpro.2012.03.132 



---



\## 📂 Folder Structure (example)

```

📁 SatelliteApp/

├── main.m

├── .cache/

├── Datasets/

│   ├── Munich/

│   │   ├── 2023\_01.jpg

│   │   ├── 2024\_01.jpg

│   │   └── ...

├── preprocess.m

├── align\_images.m

│   └── ...

├── README.md

```



---



Feel free to ⭐ star or 🍴 fork this project if you find it useful!



