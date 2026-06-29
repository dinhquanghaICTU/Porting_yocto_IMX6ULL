
#- ví dụ bình thường khi chúng ta flash image chúng ta dùng dd -> nhưng thay vì thế nó rất chậm nên dùng bmap nó sẽ 
#nhanh hơn, nó tốt hơn dd là nó chỉ ghi những block có dữ liệu.
#- chỉ định đường dẫn để lấy bmap-tools tool ở link github khác không dùng mặc định của hãng https://github.com/01org/bmap-tools 
SRC_URI = "git://github.com/intel/bmap-tools;branch=main;protocol=https"
