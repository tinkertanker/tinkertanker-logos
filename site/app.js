const grid = document.querySelector("#logo-grid");
const logoTemplate = document.querySelector("#logo-template");
const filterTemplate = document.querySelector("#filter-template");
const filterContainer = document.querySelector("#category-filters");
const resultCount = document.querySelector("#result-count");
const emptyState = document.querySelector("#empty-state");
const loadError = document.querySelector("#load-error");
const selectionBar = document.querySelector("#selection-bar");
const selectionCount = document.querySelector("#selection-count");
const selectAll = document.querySelector("#select-all");
const clearSelection = document.querySelector("#clear-selection");
const downloadSelection = document.querySelector("#download-selection");
const downloadNotice = document.querySelector("#download-notice");

const selected = new Set();
let logos = [];
let activeCategory = "All";
let noticeTimer;

const displayName = (filename) => filename
  .replace(/\.png$/i, "")
  .replace(/^\d{2}\s+/, "")
  .replace(/\s+-\s+(?:\d+w|\d+\s+w)$/i, "")
  .replace(/\s+(?:\d+w|\d+\s+w)$/i, "")
  .replace(/\s+/g, " ");

const visibleLogos = () => logos.filter(
  (logo) => activeCategory === "All" || logo.category === activeCategory,
);

const showNotice = (message) => {
  window.clearTimeout(noticeTimer);
  downloadNotice.textContent = message;
  downloadNotice.hidden = false;
  noticeTimer = window.setTimeout(() => {
    downloadNotice.hidden = true;
  }, 3600);
};

const updateSelectionUI = () => {
  const count = selected.size;
  const visible = visibleLogos();
  const visibleSelected = visible.filter((logo) => selected.has(logo.slug)).length;

  selectionCount.textContent = count;
  selectionBar.hidden = count === 0;
  downloadSelection.querySelector("span:last-child").textContent =
    count === 1 ? "Download 1" : `Download ${count}`;
  selectAll.checked = visible.length > 0 && visibleSelected === visible.length;
  selectAll.indeterminate = visibleSelected > 0 && visibleSelected < visible.length;
};

const triggerDownload = (logo) => {
  const link = document.createElement("a");
  link.href = logo.path;
  link.download = logo.filename;
  link.hidden = true;
  document.body.append(link);
  link.click();
  link.remove();
};

const downloadMany = async () => {
  const files = logos.filter((logo) => selected.has(logo.slug));
  if (files.length === 0) return;

  showNotice(
    files.length === 1
      ? "Your logo is downloading."
      : `${files.length} logos are downloading separately. Your browser may ask for permission.`,
  );

  for (const logo of files) {
    triggerDownload(logo);
    await new Promise((resolve) => window.setTimeout(resolve, 180));
  }
};

const renderLogos = () => {
  const visible = visibleLogos();
  grid.replaceChildren();
  emptyState.hidden = visible.length > 0;
  resultCount.textContent = `${visible.length} ${visible.length === 1 ? "logo" : "logos"}`;

  visible.forEach((logo, index) => {
    const fragment = logoTemplate.content.cloneNode(true);
    const item = fragment.querySelector(".logo-item");
    const stage = fragment.querySelector(".logo-stage");
    const image = fragment.querySelector("img");
    const checkbox = fragment.querySelector("input");
    const checkboxLabel = fragment.querySelector(".logo-select .sr-only");
    const download = fragment.querySelector(".item-download");
    const heading = fragment.querySelector("h2");
    const category = fragment.querySelector(".logo-category");
    const size = fragment.querySelector(".logo-size");
    const name = displayName(logo.filename);

    item.style.setProperty("--item-index", index);
    item.dataset.slug = logo.slug;
    stage.dataset.preview = logo.preview;
    image.src = logo.path;
    image.alt = name;
    image.width = logo.width;
    image.height = logo.height;
    checkbox.checked = selected.has(logo.slug);
    checkbox.setAttribute("aria-label", `Select ${name}`);
    checkboxLabel.textContent = `Select ${name}`;
    download.href = logo.path;
    download.download = logo.filename;
    download.setAttribute("aria-label", `Download ${name} PNG`);
    heading.textContent = name;
    heading.title = logo.filename;
    category.textContent = logo.category;
    size.textContent = `${logo.width.toLocaleString()} × ${logo.height.toLocaleString()}`;

    checkbox.addEventListener("change", () => {
      if (checkbox.checked) selected.add(logo.slug);
      else selected.delete(logo.slug);
      updateSelectionUI();
    });

    download.addEventListener("click", () => showNotice(`${name} is downloading.`));
    grid.append(fragment);
  });

  updateSelectionUI();
};

const renderFilters = () => {
  const preferredOrder = ["Tinkertanker", "Tinkercademy", "Legacy"];
  const available = new Set(logos.map((logo) => logo.category));
  const categories = ["All", ...preferredOrder.filter((category) => available.has(category))];

  categories.forEach((category) => {
    const fragment = filterTemplate.content.cloneNode(true);
    const button = fragment.querySelector("button");
    button.textContent = category;
    button.dataset.category = category;
    button.setAttribute("aria-pressed", category === activeCategory ? "true" : "false");
    button.addEventListener("click", () => {
      activeCategory = category;
      filterContainer.querySelectorAll("button").forEach((filter) => {
        filter.setAttribute("aria-pressed", filter.dataset.category === category ? "true" : "false");
      });
      renderLogos();
    });
    filterContainer.append(fragment);
  });
};

selectAll.addEventListener("change", () => {
  visibleLogos().forEach((logo) => {
    if (selectAll.checked) selected.add(logo.slug);
    else selected.delete(logo.slug);
  });
  renderLogos();
});

clearSelection.addEventListener("click", () => {
  selected.clear();
  renderLogos();
});

downloadSelection.addEventListener("click", downloadMany);

fetch("/logos.json")
  .then((response) => {
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  })
  .then((data) => {
    logos = data.items;
    renderFilters();
    renderLogos();
  })
  .catch((error) => {
    console.error("Unable to load logos", error);
    resultCount.textContent = "Unavailable";
    loadError.hidden = false;
  });
