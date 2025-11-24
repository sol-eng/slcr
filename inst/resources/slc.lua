function Meta(meta)
  -- Add the production CSS and JavaScript for SLC chunks
  local resources = [[
<style>
/* Style SLC code chunks with grey background */
div.sourceCode[data-engine="slc"],
pre.sourceCode[data-engine="slc"],
.cell[data-engine="slc"] pre.sourceCode,
.cell[data-engine="slc"] .sourceCode {
  background-color: #f5f5f5 !important;
}

/* Alternative selectors for SLC code chunks */
pre.slc,
code.slc,
.slc pre,
.slc code {
  background-color: #f5f5f5 !important;
}

/* Apply grey background to SLC chunks */
.slc-chunk pre.sourceCode,
.slc-chunk .sourceCode {
  background-color: #f5f5f5 !important;
}

/* Collapsible SLC output styling */
.slc-output-collapsible {
  border: 1px solid #ddd;
  border-radius: 6px;
  margin: 10px 0;
  background-color: #fafafa;
}

.slc-output-collapsible summary {
  background-color: #f0f0f0;
  padding: 10px 15px;
  cursor: pointer;
  font-weight: bold;
  font-size: 0.9em;
  border-bottom: 1px solid #ddd;
  user-select: none;
}

.slc-output-collapsible summary:hover {
  background-color: #e8e8e8;
}

.slc-output-collapsible[open] summary {
  border-bottom: 1px solid #ddd;
}

.slc-output-collapsible pre {
  margin: 0;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 0 0 6px 6px;
}

/* SAS syntax highlighting for SLC chunks */
.slc-chunk .sourceCode .kw,
.slc-chunk .sourceCode .cf {
  color: #0000ff !important;
  font-weight: bold;
}

.slc-chunk .sourceCode .st {
  color: #008000 !important;
}

.slc-chunk .sourceCode .co {
  color: #808080 !important;
  font-style: italic;
}

.slc-chunk .sourceCode .fu {
  color: #000080 !important;
}

.slc-chunk .sourceCode .dt {
  color: #800080 !important;
}
</style>

<script>
document.addEventListener('DOMContentLoaded', function() {
  setTimeout(function() {
    processSlcChunks();
  }, 500);

  function processSlcChunks() {
    const cells = document.querySelectorAll('.cell');

    cells.forEach(function(cell) {
      const codeElements = cell.querySelectorAll('code');

      codeElements.forEach(function(code) {
        const codeText = code.textContent || code.innerText;

        // Check if this code contains SLC keywords
        if (codeText.includes('proc print') ||
            codeText.includes('data _null_') ||
            codeText.includes('datalines') ||
            codeText.includes('data want') ||
            codeText.includes('run;')) {

          // Add the SLC styling class to the parent cell
          cell.classList.add('slc-chunk');

          // Apply grey background to code blocks in this cell
          const codeBlocks = cell.querySelectorAll('pre.sourceCode');
          codeBlocks.forEach(function(block) {
            block.style.backgroundColor = '#f5f5f5';
          });

          // Also try to find the div.sourceCode
          const sourceDiv = cell.querySelector('div.sourceCode');
          if (sourceDiv) {
            sourceDiv.style.backgroundColor = '#f5f5f5';
          }

          // Make outputs collapsible
          const output = cell.querySelector('.cell-output');
          if (output && !output.querySelector('details')) {
            const details = document.createElement('details');
            const summary = document.createElement('summary');

            details.className = 'slc-output-collapsible';
            summary.textContent = '📊 SLC Output';
            details.open = false; // Collapsed by default

            const outputContent = output.innerHTML;
            output.innerHTML = '';

            details.appendChild(summary);
            details.innerHTML += outputContent;
            output.appendChild(details);
          }
        }
      });
    });
  }
});
</script>
]]

  quarto.doc.include_text("in-header", resources)
  return meta
end

return {
  { Meta = Meta }
}
