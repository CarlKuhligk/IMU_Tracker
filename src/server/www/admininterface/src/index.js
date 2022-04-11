import React from "react";
import ReactDOM from "react-dom";
import "./index.css";
import App from "./App";
import reportWebVitals from "./reportWebVitals";

import Box from "@mui/material/Box";
import BottomNavigation from "@mui/material/BottomNavigation";
import BottomNavigationAction from "@mui/material/BottomNavigationAction";
import Device from "./cellphone.png";
import Events from "./calendar-search.png";
import Info from "./information-outline.png";

class Navigation extends React.Component {
  constructor() {
    const [value, setValue] = React.useState(0);
  }

  render() {
    return (
      <Box sx={{ width: 500 }}>
        <BottomNavigation
          showLabels
          value={value}
          onChange={(event, newValue) => {
            setValue(newValue);
          }}
        >
          <BottomNavigationAction label="Recents" icon={<Device />} />
          <BottomNavigationAction label="Favorites" icon={<Events />} />
          <BottomNavigationAction label="Nearby" icon={<Info />} />
        </BottomNavigation>
      </Box>
    );
  }
}

ReactDOM.render(
  <React.StrictMode>
    <Navigation />,
  </React.StrictMode>,
  document.getElementById("root")
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
