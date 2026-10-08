part of '../dashboard_screen.dart';

extension _marketing_pageExt on _DashboardScreenState {
  Widget _buildMarketingPage() {
    return _moduleCard(
      title: 'Marketing & Loyalty',
      action: ElevatedButton.icon(
        onPressed: () async {
          final coupon = await _showCouponDialog();
          if (coupon == null) return;
          setState(() {
            _coupons.add(coupon);
          });
          await _enqueueSync('INSERT', 'coupons', coupon.code);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiRadius.md),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Create Coupon'),
      ),
      child: SizedBox(
        height: 520,
        child: _coupons.isEmpty
            ? const Center(child: Text('No campaigns yet.'))
            : ListView.builder(
                itemCount: _coupons.length,
                itemBuilder: (context, index) {
                  final c = _coupons[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${c.code}  -  ${c.discountPercent.toStringAsFixed(1)}%',
                      ),
                      subtitle: Text(c.description),
                      trailing: Switch(
                        value: c.active,
                        onChanged: (v) async {
                          setState(() {
                            c.active = v;
                          });
                          await _enqueueSync('UPDATE', 'coupons', c.code);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
