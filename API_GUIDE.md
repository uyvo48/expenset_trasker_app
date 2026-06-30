  # Hướng Dẫn Sử Dụng & Chi Tiết API (API Documentation Guide)

  Tài liệu này chứa **toàn bộ thông tin chi tiết và đầy đủ nhất** về tất cả 34 endpoint API trong dự án **Expense Tracker**.

  Mỗi API đều có đầy đủ thông tin về: phương thức HTTP, đường dẫn, quyền truy cập, dữ liệu đầu vào (Request Body / Query Params / Path Params), dữ liệu trả về khi thành công (Success Response), và dữ liệu trả về khi có lỗi (Error Response).

  ---

  ## 📖 1. Tổng Quan Luồng Hoạt Động (API Workflow)

  1.  **Đăng ký & Đăng nhập**: User thực hiện Đăng ký (`POST /auth/register`), sau đó Đăng nhập (`POST /auth/login`) để lấy `access_token` và `refresh_token`.
  2.  **Xác thực API**: Gắn `access_token` vào Header của mỗi Request đến các API nhóm `/api/*` dưới dạng:
      `Authorization: Bearer <Your_Access_Token>`
  3.  **Làm mới Token**: Khi Access Token hết hạn (15 phút), gọi API `POST /auth/refresh` gửi kèm `refresh_token` để nhận Access Token mới mà không cần đăng nhập lại.

  ---

  ## 📡 2. Danh Sách Chi Tiết Toàn Bộ API Endpoints

  ### 🔑 2.1. Nhóm Xác Thực & Bảo Mật (Authentication & Security)

  #### 1. Đăng ký tài khoản (`POST /auth/register`)
  *   **Xác thực**: Không yêu cầu.
  *   **Request Body (JSON)**:
      *   `email` (string, bắt buộc, định dạng email): Email của user.
      *   `password` (string, bắt buộc): Mật khẩu.
      ```json
      {
        "email": "user@example.com",
        "password": "SecurePassword123"
      }
      ```
  *   **Success Response (201 Created)**:
      ```json
      {
        "message": "Đăng ký thành công"
      }
      ```
  *   **Error Response (400 Bad Request / 409 Conflict)**:
      ```json
      {
        "error": "Email đã tồn tại"
      }
      ```

  #### 2. Đăng nhập (`POST /auth/login`)
  *   **Xác thực**: Không yêu cầu.
  *   **Request Body (JSON)**:
      *   `email` (string, bắt buộc, định dạng email)
      *   `password` (string, bắt buộc)
      ```json
      {
        "email": "user@example.com",
        "password": "SecurePassword123"
      }
      ```
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Đăng nhập thành công",
        "access_token": "eyJhbGciOi...",
        "refresh_token": "eyJhbGciOi..."
      }
      ```
  *   **Error Response (401 Unauthorized)**:
      ```json
      {
        "error": "Email hoặc mật khẩu không đúng"
      }
      ```

  #### 3. Làm mới Access Token (`POST /auth/refresh`)
  *   **Xác thực**: Không yêu cầu.
  *   **Request Body (JSON)**:
      *   `refresh_token` (string, bắt buộc): Refresh Token nhận được từ API login.
      ```json
      {
        "refresh_token": "eyJhbGciOi..."
      }
      ```
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Làm mới token thành công",
        "access_token": "eyJhbGciOi..."
      }
      ```

  #### 4. Thay đổi mật khẩu (`PUT /api/change-password`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `old_password` (string, bắt buộc): Mật khẩu cũ.
      *   `new_password` (string, bắt buộc): Mật khẩu mới.
      ```json
      {
        "old_password": "SecurePassword123",
        "new_password": "NewSecurePassword456"
      }
      ```
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Đổi mật khẩu thành công"
      }
      ```

  ---

  ### 👤 2.2. Nhóm Hồ Sơ Người Dùng (User Profile)

  #### 5. Xem thông tin cá nhân (`GET /api/profile`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**:
      ```json
      {
        "id": 1,
        "username": "user",
        "email": "user@example.com",
        "created_at": "2026-06-24T12:00:00Z"
      }
      ```

  #### 6. Cập nhật hồ sơ cá nhân (`PUT /api/profile`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `username` (string): Tên hiển thị mới.
      *   `email` (string): Email mới.
      ```json
      {
        "username": "User Pro",
        "email": "userpro@example.com"
      }
      ```
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Cập nhật hồ sơ thành công",
        "data": {
          "id": 1,
          "username": "User Pro",
          "email": "userpro@example.com",
          "created_at": "2026-06-24T12:00:00Z"
        }
      }
      ```

  ---

  ### 📊 2.3. Nhóm Trang Chủ & Phân Tích (Dashboard & Analytics)

  #### 7. Số liệu tổng quan trang chủ (`GET /api/dashboard`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**:
      ```json
      {
        "total_income": 25000000,
        "total_expense": 12000000,
        "balance": 13000000,
        "transaction_count": 42,
        "monthly_income": 5000000,
        "monthly_expense": 3000000,
        "monthly_balance": 2000000
      }
      ```

  #### 8. Thống kê chi tiêu theo danh mục (`GET /api/analytics/categories`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**:
      ```json
      [
        {
          "category": "Food",
          "total_amount": 4500000,
          "percentage": 37.5
        },
        {
          "category": "Rent",
          "total_amount": 5000000,
          "percentage": 41.7
        }
      ]
      ```

  ---

  ### 💸 2.4. Nhóm Giao Dịch Cá Nhân (Transactions)

  #### 9. Lấy danh sách giao dịch cá nhân (`GET /api/transactions`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Query Params (Tùy chọn)**:
      *   `wallet_id` (int): Chỉ lấy giao dịch của một ví cụ thể.
  *   **Success Response (200 OK)**:
      ```json
      [
        {
          "id": 1,
          "user_id": 1,
          "wallet_id": 1,
          "type": "expense",
          "amount": 50000,
          "category": "Food",
          "description": "Ăn sáng bánh mì",
          "date": "2026-06-24T07:00:00Z",
          "created_at": "2026-06-24T07:05:00Z"
        }
      ]
      ```

  #### 10. Tạo giao dịch mới (`POST /api/transactions`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `amount` (int, bắt buộc, > 0): Số tiền giao dịch.
      *   `category` (string, bắt buộc): Danh mục chi tiêu (ví dụ: Food, Entertainment...).
      *   `type` (string, bắt buộc): `"income"` hoặc `"expense"`.
      *   `description` (string, tùy chọn): Ghi chú giao dịch.
      *   `date` (string/ISO-8601, tùy chọn): Ngày giao dịch.
      *   `wallet_id` (uint, tùy chọn): ID Ví thực hiện giao dịch.
      ```json
      {
        "amount": 10000000,
        "category": "Salary",
        "type": "income",
        "description": "Lương tháng 6",
        "wallet_id": 1
      }
      ```
  *   **Logic nâng cao**:
      *   Nếu gắn `wallet_id`: Ví sẽ tự động cộng tiền (nếu `type` là `income`) hoặc trừ tiền (nếu `type` là `expense`).
      *   Nếu `type` là `income`: Hệ thống sẽ tự động quét các Mục tiêu tài chính (Financial Goals) đang kích hoạt chế độ tự động phân bổ (`auto_allocate = true`) để trích phần trăm tương ứng chuyển vào mục tiêu tài chính đó.
  *   **Success Response (201 Created)**:
      ```json
      {
        "message": "Đã thêm giao dịch thành công",
        "data": {
          "id": 15,
          "user_id": 1,
          "wallet_id": 1,
          "type": "income",
          "amount": 10000000,
          "category": "Salary",
          "description": "Lương tháng 6",
          "date": "2026-06-24T15:21:00Z"
        }
      }
      ```

  #### 11. Cập nhật giao dịch (`PUT /api/transactions/:id`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Path Param**: `:id` (ID của giao dịch).
  *   **Request Body (JSON)**: Các trường tương tự như API Tạo giao dịch.
  *   **Logic nâng cao**: Tự động hoàn trả số dư của ví cũ theo giao dịch cũ và áp dụng số tiền giao dịch mới vào ví mới.
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Cập nhật giao dịch thành công",
        "data": { ... }
      }
      ```

  #### 12. Xóa giao dịch (`DELETE /api/transactions/:id`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Logic nâng cao**: Hỗ trợ Soft-delete (xóa ảo bằng GORM) và tự động hoàn trả (hoàn tác) số dư của ví chịu ảnh hưởng bởi giao dịch đó.
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Xóa giao dịch thành công"
      }
      ```

  #### 13. Tìm kiếm giao dịch nâng cao (`GET /api/transactions/search`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Query Params**:
      *   `keyword` (string): Tìm trong mô tả/ghi chú.
      *   `category` (string): Lọc theo danh mục.
      *   `type` (string): Lọc theo loại `income`/`expense`.
      *   `start_date` (string/ISO-8601) & `end_date` (string/ISO-8601): Lọc theo khoảng thời gian.
  *   **Success Response (200 OK)**:
      ```json
      {
        "count": 3,
        "data": [ ... ]
      }
      ```

  ---

  ### 💼 2.5. Nhóm Ví Tiền (Wallets)

  #### 14. Lấy danh sách ví (`GET /api/wallets`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**: Trả về danh sách ví do user tạo hoặc ví mà user được làm thành viên.
      ```json
      [
        {
          "id": 1,
          "name": "Ví cá nhân",
          "description": "Tiền tiêu hàng ngày",
          "balance": 5200000,
          "created_by": 1
        }
      ]
      ```

  #### 15. Tạo ví mới (`POST /api/wallets`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `name` (string, bắt buộc)
      *   `description` (string)
      ```json
      {
        "name": "Ví Tiết Kiệm Chung",
        "description": "Ví chung phòng trọ"
      }
      ```
  *   **Success Response (201 Created)**:
      ```json
      {
        "message": "Tạo ví thành công",
        "data": {
          "id": 2,
          "name": "Ví Tiết Kiệm Chung",
          "description": "Ví chung phòng trọ",
          "balance": 0,
          "created_by": 1
        }
      }
      ```

  #### 16. Xem chi tiết ví và thành viên ví (`GET /api/wallets/:id`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**:
      ```json
      {
        "id": 2,
        "name": "Ví Tiết Kiệm Chung",
        "description": "Ví chung phòng trọ",
        "balance": 350000,
        "members": [
          { "id": 1, "username": "admin", "email": "admin@gmail.com" },
          { "id": 2, "username": "user2", "email": "user2@gmail.com" }
        ]
      }
      ```

  #### 17. Mời một user khác vào ví chung (`POST /api/wallets/:id/invite`)
  *   **Xác thực**: Yêu cầu Token (phải là chủ ví).
  *   **Request Body (JSON)**:
      *   `email` (string, bắt buộc): Email của user cần mời (đã có tài khoản trên hệ thống).
      ```json
      {
        "email": "user2@gmail.com"
      }
      ```
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Đã mời thành viên thành công"
      }
      ```

  ---

  ### 🎯 2.6. Nhóm Mục Tiêu Tài Chính (Financial Goals)

  #### 18. Xem danh sách mục tiêu tài chính (`GET /api/goals`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**:
      ```json
      {
        "count": 1,
        "data": [
          {
            "id": 1,
            "name": "Mua máy tính mới",
            "target_amount": 20000000,
            "current_amount": 5000000,
            "deadline": "2026-12-31T00:00:00Z",
            "category": "savings",
            "auto_allocate": true,
            "allocate_percent": 10,
            "progress": 25.0,
            "remaining": 15000000,
            "days_left": 190,
            "is_over_budget": false,
            "is_expired": false
          }
        ]
      }
      ```

  #### 19. Tạo mục tiêu tích lũy mới (`POST /api/goals`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `name` (string, bắt buộc)
      *   `target_amount` (int, bắt buộc, > 0)
      *   `deadline` (string/ISO-8601 date, tùy chọn)
      *   `category` (string, bắt buộc): `savings`, `travel`, `emergency`, `education`, `investment`.
      *   `icon` (string, tùy chọn)
      *   `auto_allocate` (boolean, mặc định: false)
      *   `allocate_percent` (int, từ 0-100, bắt buộc nếu `auto_allocate` là true).
      ```json
      {
        "name": "Quỹ Dự Phòng",
        "target_amount": 10000000,
        "category": "emergency",
        "auto_allocate": true,
        "allocate_percent": 5
      }
      ```
  *   **Success Response (201 Created)**:
      ```json
      {
        "message": "Tạo mục tiêu thành công",
        "data": { ... }
      }
      ```

  #### 20. Xem chi tiết tiến độ mục tiêu (`GET /api/goals/:id`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**: Trả về chi tiết tiến trình của một mục tiêu cụ thể kèm các thông số phụ trợ.

  #### 21. Cập nhật mục tiêu tài chính (`PUT /api/goals/:id`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**: Các trường tương tự API Tạo mục tiêu, cho phép chỉnh sửa trạng thái hoạt động hoặc đổi cấu hình tự động trích tiền.
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Cập nhật mục tiêu thành công",
        "data": { ... }
      }
      ```

  #### 22. Xóa mục tiêu tài chính (`DELETE /api/goals/:id`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Xóa mục tiêu thành công"
      }
      ```

  #### 23. Nạp tiền thủ công từ Ví cá nhân vào Mục tiêu (`POST /api/goals/:id/allocate`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `amount` (int, bắt buộc, > 0)
      ```json
      {
        "amount": 500000
      }
      ```
  *   **Logic**: Tiền sẽ bị trừ khỏi ví cá nhân của bạn (tạo một transaction type `"expense"` thuộc danh mục `"goal_allocation"`) và cộng trực tiếp vào thuộc tính `current_amount` của mục tiêu tài chính đó.
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Phân bổ tiền vào mục tiêu thành công",
        "data": {
          "id": 1,
          "name": "Quỹ Dự Phòng",
          "current_amount": 1000000,
          "target_amount": 10000000,
          "progress": 10,
          "allocated_amount": 500000,
          "wallet_balance": 4500000
        }
      }
      ```

  #### 24. Rút tiền từ Mục tiêu tích lũy về lại ví cá nhân (`POST /api/goals/:id/withdraw`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `amount` (int, bắt buộc, > 0)
      ```json
      {
        "amount": 200000
      }
      ```
  *   **Logic**: Giảm số tiền tích lũy của mục tiêu, cộng tiền tương ứng vào ví cá nhân và tự tạo một transaction type `"income"` thuộc danh mục `"goal_withdrawal"`.
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Rút tiền thành công",
        "data": { ... }
      }
      ```

  ---

  ### 📅 2.7. Nhóm Chi Tiêu Định Kỳ (Recurring Transactions)

  #### 25. Xem danh sách cấu hình định kỳ (`GET /api/recurring`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**: Danh sách các giao dịch lặp lại đang thiết lập.

  #### 26. Tạo lịch trình định kỳ mới (`POST /api/recurring`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `amount` (int, bắt buộc, > 0)
      *   `category` (string, bắt buộc)
      *   `type` (string, bắt buộc): `"income"` hoặc `"expense"`
      *   `note` (string)
      *   `day_of_month` (int, bắt buộc, từ 1-31): Ngày trong tháng hệ thống sẽ tự động thực thi.
      ```json
      {
        "amount": 200000,
        "category": "Netflix",
        "type": "expense",
        "note": "Gói Ultra HD gia đình",
        "day_of_month": 15
      }
      ```
  *   **Success Response (201 Created)**:
      ```json
      {
        "message": "Tạo giao dịch định kỳ thành công",
        "data": { ... }
      }
      ```

  #### 27. Bật/Tắt lịch trình định kỳ (`PUT /api/recurring/:id/toggle`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Đã đổi trạng thái giao dịch định kỳ",
        "is_active": false
      }
      ```

  #### 28. Xóa lịch trình định kỳ (`DELETE /api/recurring/:id`)
  *   **Xác thực**: Yêu cầu Token.

  ---

  ### 👥 2.8. Nhóm Quản Lý Nhóm & Thành Viên (Groups & Members)

  #### 29. Tạo nhóm chi tiêu mới (`POST /api/groups`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `name` (string, bắt buộc)
      *   `description` (string)
      ```json
      {
        "name": "Nhóm Đi Du Lịch Đà Lạt",
        "description": "Nhóm đi Đà Lạt hè 2026"
      }
      ```
  *   **Success Response (201 Created)**: Trực tiếp tạo nhóm và tự động gắn User tạo làm thành viên nhóm đầu tiên với Role `"admin"`.
      ```json
      {
        "message": "Tạo nhóm thành công",
        "data": {
          "id": 1,
          "name": "Nhóm Đi Du Lịch Đà Lạt",
          "created_by": 1
        }
      }
      ```

  #### 30. Xem danh sách nhóm đã tham gia (`GET /api/groups`)
  *   **Xác thực**: Yêu cầu Token.

  #### 31. Xem chi tiết thông tin và thành viên của Nhóm (`GET /api/groups/:id`)
  *   **Xác thực**: Yêu cầu Token (phải là thành viên nhóm).
  *   **Success Response (200 OK)**:
      ```json
      {
        "id": 1,
        "name": "Nhóm Đi Du Lịch Đà Lạt",
        "description": "Nhóm đi Đà Lạt hè 2026",
        "created_by": 1,
        "members": [
          { "id": 1, "group_id": 1, "user_id": 1, "guest_name": "", "role": "admin" },
          { "id": 2, "group_id": 1, "user_id": null, "guest_name": "Nam (Khách)", "role": "member" }
        ]
      }
      ```

  #### 32. Thêm thành viên mới vào Nhóm (`POST /api/groups/:id/members`)
  *   **Xác thực**: Yêu cầu Token (thành viên nhóm).
  *   **Request Body (JSON)**:
      *   `email` (string, tùy chọn): Truyền email nếu người này đã có tài khoản hệ thống.
      *   `guest_name` (string, tùy chọn): Dùng khi người này không có tài khoản, hệ thống sẽ tạo một "thành viên ảo" (Guest) để ghi nợ hộ.
      ```json
      {
        "guest_name": "Hoa (Bạn Nam)"
      }
      ```
  *   **Success Response (200 OK)**:
      ```json
      {
        "message": "Thêm thành viên thành công"
      }
      ```

  #### 33. Xóa thành viên khỏi nhóm (`DELETE /api/groups/:id/members/:member_id`)
  *   **Xác thực**: Yêu cầu Token (phải là Admin nhóm).

  ---

  ### ⚖️ 2.9. Chia Hóa Đơn & Tất Toán Nợ (Shared Bills & Settlement)

  #### 34. Tạo hóa đơn chi tiêu nhóm (`POST /api/groups/:id/bills`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Path Param**: `:id` (ID của Group).
  *   **Request Body (JSON)**:
      *   `amount` (int, bắt buộc, > 0): Tổng số tiền thanh toán của hóa đơn.
      *   `payer_member_id` (uint, bắt buộc): ID của người trả tiền (lấy từ bảng `group_members`).
      *   `category` (string, bắt buộc): Danh mục chi tiêu.
      *   `description` (string): Mô tả hóa đơn.
      *   `split_method` (string, bắt buộc): `"equal"` (chia đều) hoặc `"exact"` (chia số tiền tùy chỉnh).
      *   `splits` (array, bắt buộc): Mảng phân bổ chi phí.
          *   `group_member_id` (uint, bắt buộc): ID thành viên chịu nợ.
          *   `amount` (int): Số tiền cụ thể phải chịu (bắt buộc nếu chọn phương thức `"exact"`).
      
      *Ví dụ chia đều hóa đơn 150k cho 3 người:*
      ```json
      {
        "amount": 150000,
        "payer_member_id": 1,
        "category": "Food",
        "description": "Ăn tối lẩu nướng",
        "split_method": "equal",
        "splits": [
          { "group_member_id": 1 },
          { "group_member_id": 2 },
          { "group_member_id": 3 }
        ]
      }
      ```
  *   **Success Response (201 Created)**:
      ```json
      {
        "message": "Tạo hóa đơn thành công"
      }
      ```

  #### 35. Lấy danh sách hóa đơn nhóm (`GET /api/groups/:id/bills`)
  *   **Xác thực**: Yêu cầu Token.

  #### 36. Tính toán công nợ và rút gọn đối chiếu (`GET /api/groups/:id/balances`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Logic**: Hệ thống sẽ tự tổng hợp mọi hóa đơn chưa trả và các khoản đã thanh toán nợ trước đây để tính ra công nợ cuối cùng của từng thành viên nhóm theo thuật toán tối thiểu hóa giao dịch chuyển khoản.
  *   **Success Response (200 OK)**:
      ```json
      {
        "group_id": 1,
        "group_name": "Nhóm Đi Du Lịch Đà Lạt",
        "balances": [
          {
            "member_id": 2,
            "user_id": null,
            "guest_name": "Nam (Khách)",
            "username": "",
            "owes": [
              {
                "to_member_id": 1,
                "to_username": "admin",
                "amount": 50000
              }
            ],
            "gets_back": []
          }
        ]
      }
      ```

  #### 37. Xác nhận tất toán nợ/trả nợ (`POST /api/groups/:id/settle`)
  *   **Xác thực**: Yêu cầu Token.
  *   **Request Body (JSON)**:
      *   `from_member_id` (uint, bắt buộc): ID thành viên chuyển khoản trả tiền.
      *   `to_member_id` (uint, bắt buộc): ID thành viên nhận tiền.
      *   `amount` (int, bắt buộc, > 0): Số tiền trả.
      ```json
      {
        "from_member_id": 2,
        "to_member_id": 1,
        "amount": 50000
      }
      ```
  *   **Success Response (201 Created)**:
      ```json
      {
        "message": "Xác nhận trả nợ thành công",
        "data": {
          "id": 1,
          "group_id": 1,
          "from_id": 2,
          "to_id": 1,
          "amount": 50000,
          "created_at": "2026-06-24T15:30:00Z"
        }
      }
      ```

  ---

  ## 💻 3. Hướng Dẫn Sử Dụng Bằng Postman / Insomnia

  Để cấu hình kiểm thử nhanh dự án trên ứng dụng **Postman**:

  1.  **Thiết lập Environment**:
      *   Tạo biến `base_url` = `http://localhost:8080`
      *   Tạo biến `token` = rỗng.
  2.  **Đăng nhập tự động cập nhật Token**:
      *   Tạo một request `POST {{base_url}}/auth/login`
      *   Tại tab **Tests** của request Login trong Postman, chèn đoạn code JavaScript sau để tự lưu Token sau khi đăng nhập thành công:
          ```javascript
          var jsonData = pm.response.json();
          if (jsonData.access_token) {
              pm.environment.set("token", jsonData.access_token);
          }
          ```
  3.  **Cấu hình Authorization cho các API khác**:
      *   Mở thư mục chứa các request API trong Postman.
      *   Chọn tab **Authorization**, đặt Type là **Bearer Token**.
      *   Tại ô Token, điền biến: `{{token}}`.
      *   Như vậy toàn bộ các API con trong thư mục sẽ tự động kế thừa Access Token này mà bạn không cần cấu hình thủ công cho từng API.
