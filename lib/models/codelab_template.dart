class CodeLabTemplate {
  final String id;
  final String title;
  final String category;
  final String description;
  final String iconName;
  final String code;

  const CodeLabTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.iconName,
    required this.code,
  });

  static const List<CodeLabTemplate> cbcCurriculumTemplates = [
    CodeLabTemplate(
      id: 'mpesa_calc',
      title: 'M-Pesa Fee Calculator',
      category: 'Math & Commerce',
      description: 'Calculate transaction fees, VAT, and remaining balance using JS math.',
      iconName: 'calculator',
      code: '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>M-Pesa Calculator</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      background: #0F172A;
      color: #F8FAFC;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      padding: 16px;
    }
    .box {
      background: #1E293B;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 24px;
      width: 100%;
      max-width: 360px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.5);
    }
    h2 { color: #00D06C; margin-top: 0; font-size: 22px; }
    label { font-size: 13px; color: #94A3B8; display: block; margin-top: 12px; }
    input {
      width: 100%;
      padding: 10px 12px;
      border-radius: 8px;
      border: 1px solid #475569;
      background: #0F172A;
      color: white;
      font-size: 16px;
      box-sizing: border-box;
      margin-top: 6px;
    }
    button {
      width: 100%;
      background: #00D06C;
      color: #0F172A;
      font-weight: 700;
      border: none;
      padding: 12px;
      border-radius: 8px;
      margin-top: 18px;
      cursor: pointer;
      font-size: 15px;
    }
    .receipt {
      margin-top: 20px;
      padding: 14px;
      background: #0F172A;
      border-radius: 8px;
      border-left: 4px solid #00D06C;
      font-size: 14px;
      line-height: 1.6;
    }
  </style>
</head>
<body>
  <div class="box">
    <h2>💸 M-Pesa Fee Calculator</h2>
    <label for="amount">Enter Amount (KES):</label>
    <input type="number" id="amount" placeholder="e.g. 1500" value="1000">

    <button onclick="calculateFee()">Compute Fee</button>

    <div class="receipt" id="receipt">
      Click 'Compute Fee' to see the breakdown.
    </div>
  </div>

  <script>
    function calculateFee() {
      const amount = parseFloat(document.getElementById('amount').value);
      if (isNaN(amount) || amount <= 0) {
        document.getElementById('receipt').innerHTML = '<span style="color:#F87171;">Please enter a valid amount.</span>';
        return;
      }

      let fee = 0;
      if (amount <= 100) fee = 0;
      else if (amount <= 500) fee = 7;
      else if (amount <= 1000) fee = 13;
      else if (amount <= 2500) fee = 23;
      else if (amount <= 5000) fee = 34;
      else fee = 55;

      const totalDeducted = amount + fee;

      document.getElementById('receipt').innerHTML = `
        <strong>Amount to Send:</strong> KES \${amount.toLocaleString()}<br>
        <strong>Transaction Fee:</strong> KES \${fee}<br>
        <hr style="border-color:#334155; margin: 8px 0;">
        <strong>Total Deducted:</strong> <span style="color:#00D06C; font-weight:bold;">KES \${totalDeducted.toLocaleString()}</span>
      `;
    }
  </script>
</body>
</html>''',
    ),
    CodeLabTemplate(
      id: 'wildlife_quiz',
      title: 'Kenyan Wildlife Quiz',
      category: 'Biology & CS',
      description: 'Interactive quiz game tracking score and answering with dynamic feedback.',
      iconName: 'paw',
      code: '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kenyan Wildlife Quiz</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      background: #090D16;
      color: #E2E8F0;
      padding: 20px;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
    }
    .quiz-card {
      background: #131B2E;
      border: 1px solid #1E293B;
      border-radius: 16px;
      padding: 24px;
      max-width: 440px;
      width: 100%;
    }
    .badge {
      background: #3B82F6;
      color: white;
      font-size: 12px;
      padding: 4px 10px;
      border-radius: 20px;
      font-weight: 600;
      display: inline-block;
      margin-bottom: 12px;
    }
    h2 { margin: 0 0 16px 0; font-size: 20px; }
    .option-btn {
      width: 100%;
      background: #1E293B;
      color: #E2E8F0;
      border: 1px solid #334155;
      padding: 12px 16px;
      border-radius: 10px;
      margin-bottom: 10px;
      text-align: left;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .option-btn:hover {
      background: #2563EB;
      border-color: #3B82F6;
    }
    #result {
      margin-top: 16px;
      padding: 12px;
      border-radius: 8px;
      display: none;
      font-weight: 600;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="quiz-card">
    <span class="badge">Question 1 of 1</span>
    <h2>Which animal is known as the fastest land mammal found in Maasai Mara?</h2>

    <button class="option-btn" onclick="checkAnswer(false)">A) African Lion</button>
    <button class="option-btn" onclick="checkAnswer(true)">B) Cheetah</button>
    <button class="option-btn" onclick="checkAnswer(false)">C) Leopard</button>
    <button class="option-btn" onclick="checkAnswer(false)">D) Thomson's Gazelle</button>

    <div id="result"></div>
  </div>

  <script>
    function checkAnswer(isCorrect) {
      const res = document.getElementById('result');
      res.style.display = 'block';
      if (isCorrect) {
        res.style.background = 'rgba(52, 211, 153, 0.2)';
        res.style.color = '#34D399';
        res.innerHTML = '🎉 Hongera! Correct! Cheetahs can reach speeds up to 120 km/h.';
      } else {
        res.style.background = 'rgba(248, 113, 113, 0.2)';
        res.style.color = '#F87171';
        res.innerHTML = '❌ Jaribu tena! Think about top acceleration speed!';
      }
    }
  </script>
</body>
</html>''',
    ),
    CodeLabTemplate(
      id: 'kenya_flag_canvas',
      title: 'Kenya Flag (HTML5 Canvas)',
      category: 'Geometry & Graphics',
      description: 'Draw national flag stripes and the Maasai shield with HTML5 2D Canvas.',
      iconName: 'palette',
      code: '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kenya Flag Canvas</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      background: #0B0F19;
      color: white;
      text-align: center;
      padding: 24px;
      margin: 0;
    }
    canvas {
      border: 3px solid #334155;
      border-radius: 12px;
      box-shadow: 0 15px 30px rgba(0,0,0,0.6);
      margin-top: 16px;
    }
    p { color: #94A3B8; font-size: 14px; }
  </style>
</head>
<body>
  <h2>🇰🇪 National Flag of Kenya</h2>
  <p>Rendered with HTML5 2D Canvas & Coordinate Math</p>
  <canvas id="flagCanvas" width="450" height="300"></canvas>

  <script>
    const canvas = document.getElementById('flagCanvas');
    const ctx = canvas.getContext('2d');
    const w = canvas.width;
    const h = canvas.height;

    // Top Stripe: Black
    ctx.fillStyle = "#000000";
    ctx.fillRect(0, 0, w, h * 0.3);

    // White Divider 1
    ctx.fillStyle = "#FFFFFF";
    ctx.fillRect(0, h * 0.3, w, h * 0.05);

    // Middle Stripe: Red
    ctx.fillStyle = "#BB0000";
    ctx.fillRect(0, h * 0.35, w, h * 0.3);

    // White Divider 2
    ctx.fillStyle = "#FFFFFF";
    ctx.fillRect(0, h * 0.65, w, h * 0.05);

    // Bottom Stripe: Green
    ctx.fillStyle = "#006600";
    ctx.fillRect(0, h * 0.7, w, h * 0.3);

    // Maasai Shield Center (Oval)
    ctx.save();
    ctx.beginPath();
    ctx.ellipse(w / 2, h / 2, 35, 75, 0, 0, Math.PI * 2);
    ctx.fillStyle = "#880000";
    ctx.fill();
    ctx.lineWidth = 3;
    ctx.strokeStyle = "#FFFFFF";
    ctx.stroke();
    ctx.restore();
  </script>
</body>
</html>''',
    ),
    CodeLabTemplate(
      id: 'solar_orbit',
      title: 'Solar System Orbit (Physics)',
      category: 'Physics & Astronomy',
      description: 'CSS Keyframe planetary orbits and gravitational simulation.',
      iconName: 'planet',
      code: '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Solar System Orbit</title>
  <style>
    body {
      background: radial-gradient(circle, #111827 0%, #030712 100%);
      color: white;
      height: 100vh;
      margin: 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      font-family: system-ui, sans-serif;
    }
    .space {
      position: relative;
      width: 320px;
      height: 320px;
    }
    .sun {
      position: absolute;
      top: 50%;
      left: 50%;
      width: 50px;
      height: 50px;
      margin: -25px 0 0 -25px;
      background: radial-gradient(#FDE047, #F59E0B);
      border-radius: 50%;
      box-shadow: 0 0 40px #F59E0B;
    }
    .orbit {
      position: absolute;
      top: 50%;
      left: 50%;
      border: 1px dashed rgba(255,255,255,0.2);
      border-radius: 50%;
      transform: translate(-50%, -50%);
    }
    .orbit-earth {
      width: 220px;
      height: 220px;
      animation: spin 8s linear infinite;
    }
    .earth {
      position: absolute;
      top: 0;
      left: 50%;
      width: 20px;
      height: 20px;
      margin-left: -10px;
      background: #38BDF8;
      border-radius: 50%;
      box-shadow: 0 0 10px #38BDF8;
    }
    @keyframes spin {
      100% { transform: translate(-50%, -50%) rotate(360deg); }
    }
    h3 { margin-bottom: 20px; color: #94A3B8; font-weight: 400; }
  </style>
</head>
<body>
  <h3>🪐 Earth Orbiting the Sun</h3>
  <div class="space">
    <div class="sun"></div>
    <div class="orbit orbit-earth">
      <div class="earth"></div>
    </div>
  </div>
</body>
</html>''',
    ),
    CodeLabTemplate(
      id: 'ohms_law',
      title: "Ohm's Law Circuit (V = I x R)",
      category: 'Physics & Electronics',
      description: 'Interactive circuit with voltage & resistance sliders to observe current & bulb brightness.',
      iconName: 'bulb',
      code: '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ohm's Law Simulator</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      background: #0F172A;
      color: #F8FAFC;
      padding: 24px;
      text-align: center;
      margin: 0;
    }
    .card {
      background: #1E293B;
      border-radius: 16px;
      padding: 24px;
      max-width: 400px;
      margin: 0 auto;
      border: 1px solid #334155;
    }
    .bulb {
      width: 70px;
      height: 70px;
      border-radius: 50%;
      background: #475569;
      margin: 20px auto;
      transition: all 0.2s;
    }
    .control {
      margin: 16px 0;
      text-align: left;
    }
    label { font-size: 13px; color: #94A3B8; }
    input[type=range] { width: 100%; margin-top: 6px; }
    .stat {
      background: #0F172A;
      padding: 12px;
      border-radius: 8px;
      margin-top: 16px;
      font-size: 15px;
      color: #38BDF8;
      font-weight: 700;
    }
  </style>
</head>
<body>
  <div class="card">
    <h2>💡 Ohm's Law (V = I × R)</h2>
    <div id="bulb" class="bulb"></div>

    <div class="control">
      <label>Voltage (V): <span id="vVal">9</span> Volts</label>
      <input type="range" id="vInput" min="1" max="24" value="9" oninput="update()">
    </div>

    <div class="control">
      <label>Resistance (R): <span id="rVal">10</span> Ohms (Ω)</label>
      <input type="range" id="rInput" min="1" max="50" value="10" oninput="update()">
    </div>

    <div class="stat" id="currentOutput">
      Current (I) = 0.90 Amperes (A)
    </div>
  </div>

  <script>
    function update() {
      const v = parseFloat(document.getElementById('vInput').value);
      const r = parseFloat(document.getElementById('rInput').value);
      const i = v / r;

      document.getElementById('vVal').innerText = v;
      document.getElementById('rVal').innerText = r;
      document.getElementById('currentOutput').innerText = `Current (I) = \${i.toFixed(2)} Amperes (A)`;

      // Brightness logic
      const bulb = document.getElementById('bulb');
      const brightness = Math.min(1, i / 2);
      bulb.style.background = `rgba(250, 204, 21, \${0.2 + brightness * 0.8})`;
      bulb.style.boxShadow = `0 0 \${brightness * 40}px #FACC15`;
    }
    update();
  </script>
</body>
</html>''',
    ),
  ];
}
