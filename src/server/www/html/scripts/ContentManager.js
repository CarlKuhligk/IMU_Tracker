export class ContentManager {
  constructor(device) {
    this.content = document.createElement("div");
    this.content.classList.add("content");

    this.contentHeadLabel = document.createElement("label");
    this.contentHeadLabel.classList.add("contentHeadLabel");
    this.contentHeadLabel.textContent = device.employee;

    this.contentAccelerationDiagram = document.createElement("div");
    this.contentAccelerationDiagram.classList.add("accelerationHistory");
    this.contentAccelerationDiagramLabel1 = document.createElement("label");
    this.contentAccelerationDiagramLabel1.textContent = "Bewegungsverlauf";

    this.AccelerationDiagramCollection = document.createElement("div");
    this.AccelerationDiagramCollection.classList.add("diagramCollection");

    this.AccelerationDiagram = document.createElement("div");
    this.AccelerationDiagram.classList.add("diagramContainer");
    this.AccelerationDiagram.id = "accelerationDiagramPlaceholder";

    this.AccelerationDiagramLegend = document.createElement("div");
    this.AccelerationDiagramLegend.classList.add("legend");

    this.AccelerationDiagramWindow = document.createElement("div");
    this.AccelerationDiagramWindow.classList.add("window");
    this.WindowInput = document.createElement("input");
    this.WindowInput.id = "updateInterval";
    this.WindowInput.type = "text";

    this.AccelerationDiagramCurrent = document.createElement("div");
    this.AccelerationDiagramCurrent.classList.add("current");

    this.buildContentHTML();
  }

  buildContentHTML() {
    this.AccelerationDiagramCollection.appendChild(this.AccelerationDiagram);

    this.AccelerationDiagramCollection.appendChild(
      this.AccelerationDiagramLegend
    );

    this.AccelerationDiagramWindow.appendChild(this.WindowInput);
    this.AccelerationDiagramCollection.appendChild(
      this.AccelerationDiagramWindow
    );

    this.AccelerationDiagramCollection.appendChild(
      this.AccelerationDiagramCurrent
    );

    this.contentAccelerationDiagram.appendChild(
      this.contentAccelerationDiagramLabel1
    );

    this.contentAccelerationDiagram.appendChild(
      this.AccelerationDiagramCollection
    );

    this.content.appendChild(this.contentHeadLabel);
    this.content.appendChild(this.contentAccelerationDiagram);

    $(".rootContent").empty();
    $(".rootContent").append(this.content);
  }
}
