﻿CREATE DATABASE QLBH

USE QLBH

/*PHAN 1*/
/*cau 1*/
CREATE TABLE KHACHHANG(
	MAKH CHAR(4),
	HOTEN VARCHAR(40),
	DCHI VARCHAR(50),
	SODT VARCHAR(20),
	NGSINH SMALLDATETIME,
	NGDK SMALLDATETIME,
	DOANHSO MONEY,
	PRIMARY KEY(MAKH)
)
GO
CREATE TABLE NHANVIEN(
	MANV CHAR(4),
	HOTEN VARCHAR(40),
	SODT VARCHAR(20),
	NGVL SMALLDATETIME,
	PRIMARY KEY (MANV)
)
GO
CREATE TABLE SANPHAM(
	MASP CHAR(4),
	TENSP VARCHAR(40),
	DVT VARCHAR(40),
	NUOCSX VARCHAR(40),
	GIA MONEY,
	PRIMARY KEY (MASP)
)
GO
CREATE TABLE HOADON(
	SOHD INT,
	NGHD SMALLDATETIME,
	MAKH CHAR(4),
	MANV CHAR(4),
	TRIGIA MONEY,
	PRIMARY KEY (SOHD)
)
GO
CREATE TABLE CTHD(
	SOHD INT,
	MASP CHAR(4),
	SL INT,
	PRIMARY KEY (SOHD, MASP)
)
ALTER TABLE HOADON
ADD CONSTRAINT FK_HD_KH
FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)

ALTER TABLE HOADON
ADD CONSTRAINT FK_HD_NV
FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)

ALTER TABLE CTHD
ADD CONSTRAINT FK_CTHD_HD
FOREIGN KEY (SOHD) REFERENCES HOADON(SOHD)

ALTER TABLE CTHD
ADD CONSTRAINT FK_CTHD_SP
FOREIGN KEY (MASP) REFERENCES SANPHAM(MASP)
 
/*cau 2*/
ALTER TABLE SANPHAM
ADD GHICHU VARCHAR(20)

GO

/*cau 3*/
ALTER TABLE KHACHHANG
ADD LOAIKH TINYINT

/*cau 4*/
ALTER TABLE SANPHAM
ALTER COLUMN GHICHU VARCHAR(100)

GO

/*cau 5*/
ALTER TABLE SANPHAM
DROP COLUMN GHICHU

GO

/*cau 6*/
ALTER TABLE KHACHHANG
ALTER COLUMN LOAIKH VARCHAR(50)

/*cau 7*/
ALTER TABLE SANPHAM
ADD CONSTRAINT CHK_DVT CHECK(DVT IN ('cay', 'hop', 'quyen', 'chuc', 'cai'))

GO

/*cau 8*/
ALTER TABLE SANPHAM
ADD CONSTRAINT CK_GIA CHECK(GIA >=500)

GO

/*cau 9*/
ALTER TABLE CTHD
ADD CONSTRAINT CK_CTHD CHECK(SL >=1)

GO

/* cau 10 */
ALTER TABLE KHACHHANG
ADD CONSTRAINT CK_NGAYDK CHECK (NGDK > NGSINH)

/*CAU 11*/
CREATE TRIGGER TRG_HD_KH ON HOADON
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @NGDK SMALLDATETIME, @NGHD SMALLDATETIME, @MAKH CHAR(4)

	SELECT @NGHD = NGHD, @MAKH = MAKH FROM inserted

	SELECT @NGDK = NGDK 
	FROM KHACHHANG
	WHERE MAKH = @MAKH

	IF (@NGDK > @NGHD)
		BEGIN
			PRINT 'LOI! NGAY MUA HANG PHAI LON HON HOAC BANG NGAY DANG KY!'
			ROLLBACK TRANSACTION
		END
	ELSE
		PRINT 'THAO TAC THANH CONG!'
END

/*CAU 12*/
CREATE TRIGGER TRG_HD_NV ON HOADON
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @NGHD SMALLDATETIME, @NGVL SMALLDATETIME, @MANV CHAR(4)
	
	SELECT @NGHD = NGHD, @MANV = MANV FROM inserted
	
	SELECT @NGVL = NGVL FROM NHANVIEN
	WHERE MANV = @MANV

	IF (@NGVL > @NGHD)
	BEGIN
		PRINT 'LOI! NGAY TAO HOA DON PHAI LON HON HOAC BANG NGAY VAO LAM!'
		ROLLBACK TRANSACTION
	END
	ELSE
		PRINT('THANH CONG')
END

/*CAU 13*/
CREATE TRIGGER TRG_HD_CTHD ON HOADON
FOR UPDATE
AS
BEGIN
	DECLARE @SOHD INT, @SL INT

	SELECT @SOHD = SOHD FROM inserted

	SELECT @SL = COUNT(SOHD) FROM CTHD WHERE SOHD = @SOHD

	IF (@SL < 1) 
	BEGIN
		PRINT 'LOI! MOI HOA DON PHAI CO IT NHAT MOT CTHD!'
		ROLLBACK TRANSACTION
	END
	ELSE
		PRINT 'THANH CONG'
END

/*CAU 14*/
CREATE TRIGGER TRG_HD_TRIGIA ON HOADON
FOR INSERT, UPDATE
AS 
BEGIN
	DECLARE @SOHD INT, @TRIGIA MONEY, @GIA MONEY
	SET @GIA = 0

	SELECT @SOHD = SOHD, @TRIGIA = TRIGIA FROM inserted

	SELECT @GIA = SUM(TRIGIA) FROM (SELECT SL*GIA AS 'TRIGIA'
			FROM CTHD INNER JOIN SANPHAM SP ON CTHD.MASP = SP.MASP
			WHERE @SOHD = SOHD) AS T

	IF (@TRIGIA != @GIA) 
	BEGIN
		PRINT 'LOI! TRI GIA HOA DON PHAI BANG TONG SL*GIA CAC CTHD!'
		ROLLBACK TRANSACTION
	END
	ELSE
		PRINT 'THANH CONG'
END

CREATE TRIGGER TRG_CTHD_TRIGIA ON CTHD 
AFTER INSERT, DELETE, UPDATE
AS 
BEGIN
	DECLARE @SOHD INT, @TRIGIA MONEY, @TONGGIATHEM MONEY, @TONGGIATRU MONEY

	SET @TONGGIATHEM = 0
	SET @TONGGIATRU = 0

	SELECT @SOHD = SOHD, @TONGGIATHEM=SL*GIA FROM inserted INNER JOIN SANPHAM ON inserted.MASP = SANPHAM.MASP

	SELECT @SOHD = SOHD, @TONGGIATRU=SL*GIA FROM deleted INNER JOIN SANPHAM ON deleted.MASP = SANPHAM.MASP
	
	UPDATE HOADON
	SET TRIGIA = TRIGIA - @TONGGIATRU + @TONGGIATHEM
	WHERE SOHD=@SOHD
END


/*CAU 15*/
CREATE TRIGGER TRG_KH_DOANHSO ON KHACHHANG
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @MAKH CHAR(4), @DOANHSO MONEY, @TONGDS MONEY
	SET @TONGDS = 0

	SELECT @MAKH = MAKH, @DOANHSO = DOANHSO FROM inserted

	SELECT @TONGDS = SUM(TRIGIA) FROM HOADON WHERE MAKH = @MAKH GROUP BY MAKH

	IF (@DOANHSO <> @TONGDS)
	BEGIN
		PRINT 'LOI! TONG DOANH SO KHACH HANG PHAI BANG TONG TRI GIA HOA DON KHACH DA MUA!'
		ROLLBACK TRANSACTION
	END
	ELSE
		PRINT 'THANH CONG'
END

CREATE TRIGGER TRG_HOADON_DOANHSO ON HOADON 
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
	DECLARE @MAKH CHAR(4), @DOANHSO MONEY, @TONGDSTHEM MONEY, @TONGDSTRU MONEY

	SET @TONGDSTHEM = 0
	SET @TONGDSTRU = 0

	SELECT @TONGDSTHEM=TRIGIA, @MAKH=MAKH FROM inserted 
	SELECT @TONGDSTRU=TRIGIA, @MAKH=MAKH FROM deleted

	UPDATE KHACHHANG
	SET DOANHSO=@TONGDSTHEM - @TONGDSTRU
	WHERE MAKH=@MAKH
END


/*PHAN 2*/
/*CAU 1*/
SET DATEFORMAT dmy;

INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV01', 'Nguyen Nhu Nhut', '0927345678', '13/4/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV02', 'Le Thi Phi Yen', '0987567390', '21/4/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV03', 'Nguyen Van B', '0997047382', '27/4/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV04', 'Ngo Thanh Tuan', '0913758498', '24/6/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV05', 'Nguyen Thi Truc Thanh', '0918590387', '20/7/2006')

INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH01', 'Nguyen Van A', '731, Tran Hung Dao, Q5, TPHCM', '08823451', '22/10/1960', 13060000, '22/07/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH02', 'Tran Ngoc Han', '23/5 Nguyen Trai, Q5, TpHCM', '0908256478', '03/04/1974', 280000, '30/07/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH03', 'Tran Ngoc Linh', '45 Nguyen Canh Chan, Q1, TpHCM', '0938776266', '12/06/1980', 3860000, '05/08/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH04', 'Tran Minh Long', '50/34 Le Dai hanh, Q10, TpHCM', '0917325476', '09/03/1965', 250000, '02/10/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH05', 'Le Nhat Minh', '34 Truong Dinh, Q3, TPHCM', '08246108', '10/03/1960', 21000, '28/10/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH06', 'Le Hoai Thuong', '227 Nguyen Van Cu, Q5, TpHCM', '08631738', '31/12/1981', 915000, '24/11/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH07', 'Nguyen Van Tam', '32/3 Tran Binh Trong, Q5, TpHCM', '0916783565', '06/04/1971', 12500, '01/12/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH08', 'Phan Thi Thanh', '45/2 An Duong Vuong, Q5, TPHCM', '0938435756', '10/01/1971', 365000, '13/12/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH09', 'Le Ha Vinh', '873 Le Hong Phong, Q5, TPHCM', '08654763', '03/09/1979', 70000, '14/01/2007')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH10', 'Ha Duy Lap', '34/34B Nguyen Trai, Q1, TPHCM', '08768904', '02/05/1963', 67500, '16/01/2007')



INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC01', 'But Chi', 'cay', 'Singapore', 3000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC02', 'But Chi', 'cay', 'Singapore', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC03', 'But Chi', 'cay', 'Viet Nam', 3500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC04', 'But Chi', 'hop', 'Viet Nam', 30000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BB01', 'But bi', 'cay', 'Viet Nam', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BB02', 'But bi', 'cay', 'Trung Quoc', 7000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BB03', 'But bi', 'hop', 'Thai Lan', 100000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV01', 'Tap 100 giay mong', 'quyen', 'Trung Quoc', 2500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV02', 'Tap 200 giay mong', 'quyen', 'Trung Quoc', 4500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV03', 'Tap 100 giay tot', 'quyen', 'Viet Nam', 3000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV04', 'Tap 200 giay tot', 'quyen', 'Viet Nam', 5500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV05', 'Tap 100 trang', 'chuc', 'Viet Nam', 23000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV06', 'Tap 200 trang', 'chuc', 'Viet Nam', 53000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV07', 'Tap 100 trang', 'chuc', 'Viet Nam', 34000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST01', 'So tay 500 trang', 'quyen', 'Viet Nam', 40000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST02', 'So tay loai 1', 'quyen', 'Viet Nam', 55000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST03', 'So tay loai 2', 'quyen', 'Viet Nam', 51000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST04', 'So tay', 'quyen', 'Thai Lan', 55000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST05', 'So tay mong', 'quyen', 'Thai Lan', 20000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST06', 'Phan viet bang', 'hop', 'Viet Nam', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST07', 'Phan khong bui', 'hop', 'Viet Nam', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST08', 'Bong bang', 'cai', 'Viet Nam', 1000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST09', 'But long', 'cay', 'Viet Nam', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST10', 'But long', 'cay', 'Trung Quoc', 7000)

INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1001, '23/07/2006', 'KH01', 'NV01', 320000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1002, '12/08/2006', 'KH01', 'NV02', 840000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1003, '23/06/2006', 'KH02', 'NV01', 100000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1004, '01/09/2006', 'KH02', 'NV01', 180000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1005, '20/10/2006', 'KH01', 'NV02', 3800000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1006, '16/10/2006', 'KH01', 'NV03', 2430000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1007, '28/10/2006', 'KH03', 'NV03', 510000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1008, '28/10/2006', 'KH01', 'NV03', 440000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1009, '28/10/2006', 'KH03', 'NV04', 320000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1010, '01/11/2006', 'KH01', 'NV01', 5200000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1011, '04/11/2006', 'KH04', 'NV03', 250000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1012, '30/11/2006', 'KH05', 'NV03', 21000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1013, '12/12/2006', 'KH06', 'NV01', 5000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1014, '31/12/2006', 'KH03', 'NV02', 3150000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1015, '01/01/2007', 'KH06', 'NV01', 910000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1016, '01/01/2007', 'KH07', 'NV02', 12500)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1017, '02/01/2007', 'KH08', 'NV03', 35000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1018, '13/01/2007', 'KH08', 'NV03', 330000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1019, '13/01/2007', 'KH01', 'NV03', 30000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1020, '14/01/2007', 'KH09', 'NV04', 70000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1021, '16/01/2007', 'KH10', 'NV04', 67500)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1022, '16/01/2007', Null, 'NV03', 7000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1023, '17/01/2007', Null, 'NV01', 330000)

INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'TV02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'ST01', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'BC01', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'BC02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'ST08', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1002, 'BC04', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1002, 'BB01', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1002, 'BB02', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1002, 'BB03', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV01', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV03', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV04', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1005, 'TV05', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1005, 'TV06', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'TV07', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1006, 'ST01', 30)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1006, 'ST02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1007, 'ST03', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1008, 'ST04', 8)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1009, 'ST05', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'TV07', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'ST07', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'ST08', 100)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'ST04', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'TV03', 100)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1011, 'ST06', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1012, 'ST07', 3)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1013, 'ST08', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BC02', 80)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BB02', 100)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BC04', 60)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BB01', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1015, 'BB02', 30)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1015, 'BB03', 7)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1016, 'TV01', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1017, 'TV02', 1)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1017, 'TV03', 1)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1017, 'TV04', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1018, 'ST04', 6)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1019, 'ST05', 1)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1019, 'ST06', 2)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1020, 'ST07', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1021, 'ST08', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1021, 'TV01', 7)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1021, 'TV02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1022, 'TV02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1023, 'ST04', 6)

INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1023, 'BC01', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1023, 'BC02', 1)


/* cau 2*/
SELECT * INTO SANPHAM1 FROM SANPHAM
SELECT * INTO KHACHHANG1 FROM KHACHHANG

/*cau 3*/
UPDATE SANPHAM1 SET GIA = GIA + GIA*0.05 WHERE NUOCSX = 'Thai Lan'

/*cau 4*/
UPDATE SANPHAM1 SET GIA = GIA - GIA*0.05 WHERE NUOCSX = 'Trung Quoc'

/* cau 5 */
UPDATE KHACHHANG1
SET LOAIKH = 'Vip'
WHERE (DOANHSO >= 10000000 AND NGDK < '01/01/2007') OR (DOANHSO >= 2000000 AND NGDK >= '01/01/2007')


/*PHAN 3*/
/* cau 1 */
SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX = 'Trung Quoc'

/* cau 2 */
SELECT MASP, TENSP FROM SANPHAM WHERE DVT IN ('cay', 'quyen')

/* cau 3 */
SELECT MASP, TENSP FROM SANPHAM WHERE SUBSTRING(MASP, 1, 1) = 'B' AND SUBSTRING(MASP, 3, 2) = '01'

/* cau 4 */
SELECT MASP, TENSP FROM SANPHAM WHERE (NUOCSX = 'Trung Quoc') AND (GIA BETWEEN 30000 AND 40000)

/* cau 5 */
SELECT MASP, TENSP FROM SANPHAM WHERE (NUOCSX = 'Trung Quoc' OR NUOCSX = 'Thai Lan') AND (GIA BETWEEN 30000 AND 40000)

/* cau 6 */
SELECT SOHD, TRIGIA FROM HOADON WHERE NGHD BETWEEN '1/1/2007' AND '2/1/2007'

/* cau 7 */
SELECT SOHD, TRIGIA, NGHD FROM HOADON WHERE MONTH(NGHD) = 1 AND YEAR(NGHD) = 2007 ORDER BY (NGHD) ASC, (TRIGIA) DESC

/* cau 8 */
SELECT KHACHHANG.MAKH, HOTEN FROM HOADON INNER JOIN KHACHHANG ON HOADON.MAKH = KHACHHANG.MAKH WHERE NGHD = '1/1/2007' 

/* cau 9 */
SELECT SOHD, TRIGIA FROM HOADON INNER JOIN NHANVIEN ON HOADON.MANV = NHANVIEN.MANV WHERE NHANVIEN.HOTEN = 'Nguyen Van B'

/*cau 10*/
SELECT SANPHAM.MASP, TENSP FROM CTHD 
INNER JOIN SANPHAM ON CTHD.MASP = SANPHAM.MASP 
INNER JOIN HOADON ON CTHD.SOHD = HOADON.SOHD
INNER JOIN KHACHHANG ON KHACHHANG.MAKH = HOADON.MAKH
WHERE KHACHHANG.HOTEN = 'Nguyen Van A' AND MONTH(HOADON.NGHD) = 10 AND YEAR(HOADON.NGHD) = 2006

/* cau 11 */
SELECT SOHD FROM CTHD WHERE MASP = 'BB01' OR MASP = 'BB02'

/* cau 12 */
(SELECT SOHD FROM CTHD WHERE MASP = 'BB01'AND SL >= 10 AND SL <= 20)
UNION
(SELECT SOHD FROM CTHD WHERE MASP = 'BB02' AND SL >= 10 AND SL <= 20)

/* cau 13 */
(SELECT SOHD FROM CTHD WHERE MASP = 'BB01'AND SL >= 10 AND SL <= 20)
INTERSECT
(SELECT SOHD FROM CTHD WHERE MASP = 'BB02' AND SL >= 10 AND SL <= 20)

/*cau 14*/
(SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX='Trung Quoc') 
UNION
(SELECT SANPHAM.MASP, TENSP FROM SANPHAM INNER JOIN CTHD ON CTHD.MASP = SANPHAM.MASP INNER JOIN HOADON ON HOADON.SOHD = CTHD.SOHD WHERE NGHD = '1/1/2007')

/* CAU 15*/
/*C1*/
SELECT MASP, TENSP FROM SANPHAM WHERE MASP NOT IN (SELECT MASP FROM CTHD)
/*C2*/
(SELECT MASP, TENSP FROM SANPHAM)
EXCEPT
(SELECT CTHD.MASP, TENSP FROM CTHD INNER JOIN SANPHAM ON SANPHAM.MASP = CTHD.MASP)

/*CAU 16*/
SELECT MASP, TENSP FROM SANPHAM WHERE MASP 
NOT IN (SELECT MASP FROM CTHD INNER JOIN HOADON ON HOADON.SOHD = CTHD.SOHD WHERE YEAR(NGHD) = 2006)

/*CAU 17*/
SELECT MASP, TENSP FROM SANPHAM WHERE MASP 
NOT IN (SELECT MASP FROM CTHD INNER JOIN HOADON ON HOADON.SOHD = CTHD.SOHD WHERE YEAR(NGHD) = 2006) AND NUOCSX = 'Trung Quoc'

/*cau 18*/
/*tim nhung hoa don mua it nhat cac san pham cua Singapore = NOT (tim cac hoa don sao cac hoa don khong mua bat cu san pham nao cua singapore) */
SELECT DISTINCT(SOHD) FROM CTHD AS HD WHERE NOT EXISTS (
SELECT MASP FROM SANPHAM AS SP WHERE NUOCSX = 'Singapore' EXCEPT SELECT MASP FROM CTHD AS HD2 WHERE HD.SOHD = HD2.SOHD
)

SELECT DISTINCT(SOHD) FROM CTHD AS HD WHERE SOHD NOT IN (
SELECT SOHD FROM (SELECT MASP FROM SANPHAM AS SP WHERE NUOCSX = 'Singapore' EXCEPT SELECT MASP FROM CTHD AS HD2 WHERE HD.SOHD = HD2.SOHD) AS R
)

SELECT DISTINCT(SOHD) FROM CTHD AS CT1 WHERE NOT EXISTS (
	SELECT MASP FROM SANPHAM WHERE NUOCSX = 'Singapore' AND NOT EXISTS (SELECT SOHD FROM CTHD AS CT2 WHERE CT1.SOHD = CT2.SOHD AND SANPHAM.MASP = CT2.MASP)
)

/* cau 19: SU DUNG VIEW */
SELECT SOHD FROM (
		SELECT SOHD, SUM(SL) AS TOTAL FROM (
			SELECT DISTINCT(SOHD), SL FROM CTHD AS CT1 WHERE NOT EXISTS (
				SELECT MASP FROM SANPHAM WHERE NUOCSX = 'Singapore' AND NOT EXISTS (
					SELECT SOHD FROM CTHD AS CT2 WHERE CT1.SOHD = CT2.SOHD AND SANPHAM.MASP = CT2.MASP
				)
			)
		) AS T
		GROUP BY SOHD
) AS R
WHERE TOTAL <= (
	SELECT MIN(TOTAL) FROM (
		SELECT SOHD, SUM(SL) AS TOTAL FROM (
			SELECT DISTINCT(SOHD), SL FROM CTHD AS CT1 WHERE NOT EXISTS (
				SELECT MASP FROM SANPHAM WHERE NUOCSX = 'Singapore' AND NOT EXISTS (
					SELECT SOHD FROM CTHD AS CT2 WHERE CT1.SOHD = CT2.SOHD AND SANPHAM.MASP = CT2.MASP
				)
			)
		) AS T
		GROUP BY SOHD
	) AS Y
)

/*CAU 20*/
SELECT COUNT(SOHD) as SHD FROM HOADON INNER JOIN KHACHHANG ON KHACHHANG.MAKH = HOADON.MAKH
WHERE NGHD < NGDK
GROUP BY HOADON.MAKH 

/*CAU 21*/
SELECT COUNT(MASP) FROM CTHD INNER JOIN HOADON ON HOADON.SOHD = CTHD.SOHD
WHERE YEAR(NGHD) = 2006

/*cau 22 */
SELECT MAX(TRIGIA) AS TGLN FROM HOADON 

/*CAU 23*/
SELECT AVG(TRIGIA) AS TGTB FROM HOADON WHERE YEAR(NGHD) = 2007

/* CAU 24*/
SELECT SUM(TRIGIA) AS DOANHTHU FROM HOADON WHERE YEAR(NGHD) = 2006

/*CAU 25*/
SELECT SOHD FROM HOADON WHERE TRIGIA >= (SELECT MAX(TRIGIA) FROM HOADON)

/*CAU 26*/
SELECT HOTEN FROM HOADON INNER JOIN KHACHHANG ON HOADON.MAKH = KHACHHANG.MAKH 
WHERE TRIGIA >= (SELECT MAX(TRIGIA) FROM HOADON) AND YEAR(NGHD) = 2006

/* CAU 27*/
SELECT TOP 3 MAKH, HOTEN FROM KHACHHANG ORDER BY DOANHSO DESC

/*CAU 28*/
SELECT MASP, TENSP FROM SANPHAM WHERE GIA IN (SELECT DISTINCT TOP 3 GIA FROM SANPHAM ORDER BY GIA DESC)

/* CAU 29*/
SELECT MASP, TENSP FROM SANPHAM WHERE GIA IN (SELECT DISTINCT TOP 3 GIA FROM SANPHAM ORDER BY GIA DESC) AND NUOCSX = 'Thai Lan'

/*CAU 30*/
SELECT MASP, TENSP FROM SANPHAM WHERE GIA IN (SELECT DISTINCT TOP 3 GIA FROM SANPHAM ORDER BY GIA DESC) AND NUOCSX = 'Trung Quoc'

/*CAU 31*/
SELECT TOP 3 *, RANK() OVER (ORDER BY DOANHSO DESC) AS DS_RANK FROM KHACHHANG

/*CAU 32*/
SELECT COUNT(MASP) AS SPCHINA FROM SANPHAM WHERE NUOCSX = 'Trung Quoc'

/*CAU 33 */
SELECT NUOCSX, COUNT(MASP) AS SL_NUOCSX FROM SANPHAM GROUP BY NUOCSX

/*CAU 34*/
SELECT NUOCSX, MAX(GIA) AS GIALN, MIN(GIA) AS GIANN, AVG(GIA) AS GIATB FROM SANPHAM GROUP BY NUOCSX

/*CAU 35*/
SELECT SUM(TRIGIA) AS DOANHTHU, NGHD FROM HOADON GROUP BY NGHD

/*CAU 36*/
SELECT MASP, SUM(SL) AS TONGSL FROM CTHD INNER JOIN HOADON ON CTHD.SOHD = HOADON.SOHD WHERE MONTH(NGHD) = 10 AND YEAR(NGHD) = 2006
GROUP BY MASP

/*CAU 37*/
SELECT MONTH(NGHD) AS THANG, SUM(TRIGIA) AS DOANHTHU FROM HOADON WHERE YEAR(NGHD) = 2006 GROUP BY MONTH(NGHD)

/*CAU 38*/
SELECT SOHD FROM CTHD GROUP BY SOHD HAVING COUNT(DISTINCT MASP) >= 4 

/* CAU 39 */
SELECT SOHD FROM CTHD INNER JOIN SANPHAM ON CTHD.MASP = SANPHAM.MASP WHERE NUOCSX = 'Viet Nam' GROUP BY SOHD HAVING COUNT(DISTINCT CTHD.MASP) >= 3

/* CAU 40 */
SELECT MAKH, HOTEN FROM KHACHHANG
WHERE MAKH = (SELECT DISTINCT KHACHHANG.MAKH FROM KHACHHANG INNER JOIN HOADON ON KHACHHANG.MAKH = HOADON.MAKH
GROUP BY KHACHHANG.MAKH
HAVING COUNT(HOADON.SOHD) >= (SELECT MAX(VALUE) FROM (
SELECT COUNT(SOHD) AS VALUE FROM HOADON GROUP BY MAKH
) AS T)
)

/*CAU 41*/
SELECT MONTH(NGHD) AS THANGCN FROM HOADON
WHERE YEAR(NGHD) = 2006 AND TRIGIA = (SELECT MAX(TRIGIA) FROM HOADON WHERE YEAR(NGHD) = 2006)
GROUP BY MONTH(NGHD)

/*CAU 42*/
SELECT DISTINCT MASP FROM CTHD WHERE MASP IN (
SELECT SANPHAM.MASP FROM SANPHAM INNER JOIN CTHD ON SANPHAM.MASP = CTHD.MASP
GROUP BY SANPHAM.MASP
HAVING SUM(SL) <= (SELECT MIN(VAL) FROM (SELECT SUM(SL) AS VAL FROM SANPHAM INNER JOIN CTHD ON SANPHAM.MASP = CTHD.MASP
GROUP BY SANPHAM.MASP) AS T)
)

/*CAU 43*/
SELECT MASP, TENSP FROM SANPHAM AS SP1 WHERE GIA <= 
(SELECT MIN(GIA) FROM SANPHAM SP2 WHERE SP1.NUOCSX = SP2.NUOCSX GROUP BY NUOCSX )

/* CAU 44 */
SELECT NUOCSX
FROM SANPHAM
GROUP BY NUOCSX
HAVING COUNT(DISTINCT GIA)>=3

/*CAU 45*/
SELECT TOP 10 MAKH, HOTEN FROM KHACHHANG 
WHERE MAKH IN (
SELECT MAKH FROM HOADON GROUP BY MAKH HAVING COUNT(SOHD) >= (SELECT MAX(VALUE) FROM (SELECT COUNT(SOHD) AS VALUE FROM HOADON GROUP BY MAKH) AS T)
)
ORDER BY DOANHSO DESC
