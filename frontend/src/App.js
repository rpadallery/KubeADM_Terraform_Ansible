import React, { useEffect, useState } from "react";
import Gallery from "react-photo-gallery";

function App() {

  const BACKEND_URL = process.env.REACT_APP_BACKEND_URL
  const [imageGallery, setImageGallery] = useState([]);
  const [selectedImage, setSelectedImage] = useState(null);
  const [imageWidth, setImageWidth] = useState(0);
  const [imageHeight, setImageHeight] = useState(0);

  useEffect(() => {
    fetch(`${BACKEND_URL}/gallery`)
      .then(response => response.json())
      .then(data => {
        // const gallery = data.map(picture => ({ src: picture.src, height: 3, width: 4 }));
        setImageGallery(data);
      })
      .catch(err => {
        console.log(err);
      });
  }, []);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
  
  // Create a FileReader
  const reader = new FileReader();

  reader.onload = (e) => {
    const img = new Image();
    img.src = e.target.result;

    img.onload = () => {
      // Set the width and height in the state
      setImageWidth(img.width);
      setImageHeight(img.height);
    };
  };

  // Read the file as a data URL
  reader.readAsDataURL(file);

  setSelectedImage(file);
  };

  const uploadImage = () => {
    if (selectedImage) {
      const formData = new FormData();
      formData.append("image", selectedImage);
      formData.append("width", imageWidth);
      formData.append("height", imageHeight);

      fetch(`${BACKEND_URL}/upload`,{
        method: "POST",
        body: formData,
      })
        .then(response => response.json())
        .then(data => {
          // Handle the response if needed
          console.log("Image uploaded successfully:");
          fetch(`${BACKEND_URL}/gallery`)
            .then(response => response.json())
            .then(data => {
              // const gallery = data.map(picture => ({ src: picture.src, height: 3, width: 4 }));
              setImageGallery(data);
            })
            .catch(err => {
              console.log(err);
            });
        })
        .catch(err => {
          console.error("Error uploading image:", err);
        });
    }
  }

  return (
    <div>
      <input type="file" accept="image/*" onChange={handleFileChange} />
      <button onClick={uploadImage}>Add Image</button>
      <Gallery photos={imageGallery}/>
    </div>
  );
}

export default App;
